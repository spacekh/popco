; CultranDejonet.nlogo
; Marshall Abrams' based partly on the following models from the built-in NetLogo models library:
;
; Stonedahl, F. and Wilensky, U. (2008). NetLogo Virus on a Network model. http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.
; Wilensky, U. (2005). NetLogo Preferential Attachment model. http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
; Wilensky, U. (2005). NetLogo Small Worlds model. http://ccl.northwestern.edu/netlogo/models/SmallWorlds. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


; Globals set by user:
;   nodes-per-subnet
;   average-node-degree  ; avg links per node
;   trust-mean           ; mean activation passed to receiver
;   trust-stdev          ; standard deviation of normal distribution around mean
;   prob-of-transmission-bias ; allows transmission to be biased so that black or white is more likely to transmit
;   subnet1, subnet2

extensions [matrix]
  
globals
[
  max-activn       ; maximum possible node activation, i.e. degree of confidence/commitment, prob of transmission, etc.
  min-activn       ; minimum possible node activation. negative to indicate confidence/commitment in the opposite cultvar.
  stop-threshold   ; if every node's activation change from previous tick is < this, go procedure automatically stops.
  ready-to-stop    ; transmit result of activn change test before update-activns proc to after it runs.
  netlogo-person-hue ; hue of nodes for use with variation using NetLogo built-in color-mapping scheme (vs. HSB or RGB).
  node-shape       ; default node shape
  link-color       ; obvious
  inter-link-subnets-color ; links that go from one subnet to another
  inter-node-shape ; nodes that link from one subnet to another
  background-color ; obvious
  clustering-coefficient               ; the clustering coefficient of the network; this is the
                                       ; average of clustering coefficients of all persons
  average-path-length                  ; average path length of the network
  infinity                             ; a very large number.
                                       ; used to denote distance between two persons which
                                       ; don't have a connected or unconnected path between them
  nodes-showing-numbers?                      ; true when we are displaying node degrees
  subnets-matrix                       ; matrix of subnet id's showing how they're layed out in the world
  
  communities  ; list of lists of nodes representing communities we've found so far
]

breed [sides side]
breed [persons person]

persons-own
[
  activation       ; ranges from min-activn to max-activn
  next-activation  ; allows parallel updating
  node-clustering-coefficient
  distance-from-other-persons   ;; list of distances of this node from other persons
  person-subnet
  index ; temporary variable for matrix configuration
  my-community ; temporary variable for cohesion reporting and community processing
]

links-own
[
  link-subnet
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP

to setup
  clear-all
  
  set ready-to-stop false
  
  set-default-shape sides "line"
  
  set max-activn 1
  set min-activn -1
  set stop-threshold 10 ^ stop-threshold-exponent
  
  set node-shape "circle" ; "square" "target" "face happy" "x" "leaf" "star""triangle" "face sad"
  set-default-shape persons node-shape
  
  ;set background-color 73 ; a blue-green
  set background-color 17 ; peach
  ;set background-color 58
  set netlogo-person-hue 0
  set link-color 123
  set inter-link-subnets-color yellow
  set inter-node-shape "square"
  set nodes-showing-numbers? false
  set communities []
  ;output-print "vars defined"

  ask patches [set pcolor background-color]
  
  ;output-print "patches colored"
  ;output-print (sentence "number-of-subnets = " number-of-subnets)

  let i 1
  while [i <= number-of-subnets] [
    create-nodes i
    ;output-print "nodes created"
    create-network i
    ;output-print "create-network has run"
    set i i + 1
  ]
  ;output-print "net created"

  layout-network
  ;output-print "net layed out"

  reset-ticks
  ;output-print "ticks reset"
end

to create-nodes [subnet]
  create-persons nodes-per-subnet
  [
    ; for visual reasons, we don't put any nodes *too* close to the edges
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set person-subnet subnet
    setup-cultvar
  ]
end

; mostly from "Virus on a Network"--see above
; Assign a random number of links randomly between pairs of nodes, making the total number of links such
; that the average node degree per node is that specified by the user.  But try to link to physically
; near nodes.  This is therefore not an Erdos-Renyi binomial/Possion network, since pairs of
; nodes don't have equal probability of being linked: Closer nodes are overwhelmingly more likely to be linked.
; [But maybe the degree distribution is neverthless typical for an E-R net?  Don't know.]
; Algorithm:
; Keep doing the following until you've created enough links that you have average-node-degree/2 per node:
; ( /2 since each link adds a degree to two nodes)
; Choose a random person, and create a link to the physically closest person to which it's not already linked.
; Since create-nodes gave persons random locations, the link is to a random person.
; (Note that these locations will be revised by initial-layout-network.  Their only function is to group persons
; randomly--in effect to randomly order persons by closeness to any given person.)
to create-network [subnet]
  let num-links (average-node-degree * nodes-per-subnet) / 2
  while [count links with [link-subnet = subnet] < num-links ][
    ask one-of persons with [person-subnet = subnet] [
      let choice (min-one-of (other persons with [person-subnet = subnet and not link-neighbor? myself]) [distance myself])
      if choice != nobody [ create-link-with choice [set link-subnet subnet]]
    ]
  ]
  ask links[ set color link-color ]
end

to inter-link-subnets [subn1 subn2]
  if (subn1 != subn2) [
    let nodes1 persons with [person-subnet = subn1] 
    let nodes2 persons with [person-subnet = subn2]
    if (any? nodes1 and any? nodes2) [
      link-close-nodes inter-nodes-per-subnet nodes1 nodes2
    ]
  ]
end


; A kind of kludgey but effective way to choose near nodes to link from two subnets
; Chooses n nodes each from two sets, and then creates links from every one on each side to every one on the other.
; If you just want a set of single links, call repeatedly with n=1.
; BUG: I think that if the chosen nodes are already linked, it silently does nothing.
to link-close-nodes [n nodes1 nodes2]
  let from-nodes1 min-n-of n nodes1 [distance one-of nodes2]      ; find the nearest nodes to an arbitrary member of the second set
  let from-nodes2 min-n-of n nodes2 [distance one-of from-nodes1] ; now find the nearest nodes to one of the ones in the first set
  ask from-nodes1 [create-links-with from-nodes2 [set color inter-link-subnets-color]]
  ask from-nodes1 [set shape inter-node-shape]
  ask from-nodes2 [set shape inter-node-shape]
end

to layout-network
  initial-layout-network persons
  ; at this point, all of the subnets are on top of each other
  place-subnets
end

to initial-layout-network [nodes]
  repeat 10 [
    layout-spring nodes links 
                  0.1 (world-width / sqrt nodes-per-subnet) 1 ; 3rd arg was 0.3 originally
  ]
end

to place-subnets
  let subnet-lattice-dims (near-factors number-of-subnets)
  let subnet-lattice-dim1 item 0 subnet-lattice-dims
  let subnet-lattice-dim2 item 1 subnet-lattice-dims
  
  ; subnet-lattice-dim1 is always <= subnet-lattice-dim2. 
  ; Here we choose whether there should be more subnets in the x or y dimension,
  ; depending on whether the world is larger in one direction or the other. 
  let x-subnet-lattice-dim "not yet"
  let y-subnet-lattice-dim "not yet"
  if-else max-pxcor < max-pycor [ 
    set x-subnet-lattice-dim subnet-lattice-dim1
    set y-subnet-lattice-dim subnet-lattice-dim2
  ][
    set x-subnet-lattice-dim subnet-lattice-dim2
    set y-subnet-lattice-dim subnet-lattice-dim1
  ]
  
  ; initialize global matrix that will summarize the layout.  note which is x and y: matrix rows are y, and cols are x.
  set subnets-matrix matrix:make-constant y-subnet-lattice-dim x-subnet-lattice-dim 0

  let x-subnet-lattice-unit 1 / x-subnet-lattice-dim
  let y-subnet-lattice-unit 1 / y-subnet-lattice-dim
 
  stretch-network persons (.9 * x-subnet-lattice-unit) (.9 * y-subnet-lattice-unit)  ; resize the overlaid subnets as one. we'll split them up in a moment.

  let x-shift-width (x-subnet-lattice-unit * (max-pxcor - min-pxcor))
  let y-shift-width (y-subnet-lattice-unit * (max-pycor - min-pycor))
  let j 0
  let k 0
  while [j < x-subnet-lattice-dim] [
    while [k < y-subnet-lattice-dim] [
      let subnet (k * x-subnet-lattice-dim) + j + 1
      let xshift min-pxcor + ((j + .5) * x-shift-width)  ; subnets are laid out from left to right
      let yshift max-pycor - ((k + .5) * y-shift-width)  ; and from top to bottom
      shift-network-by-patches persons with [person-subnet = subnet] xshift yshift
      matrix:set subnets-matrix k j subnet ; store name of this subnet in matrix location corresponding to location in world
      set k (k + 1)
    ]
    set k 0
    set j (j + 1)
  ]
end

to link-near-subnets
  let dims matrix:dimensions subnets-matrix
  let rows item 0 dims
  let cols item 1 dims

  ; link horizontally
  let row-index 0
  let col-index 0
  while [row-index < rows] [
    while [col-index < cols - 1] [
      let subn1 matrix:get subnets-matrix row-index col-index
      let subn2 matrix:get subnets-matrix row-index (col-index + 1)
      inter-link-subnets subn1 subn2
      set col-index col-index + 1
    ]
    set row-index row-index + 1
    set col-index 0
  ]

  ; link vertically
  set row-index 0
  set col-index 0
  while [col-index < cols] [
    while [row-index < rows - 1] [
      let subn1 matrix:get subnets-matrix row-index col-index
      let subn2 matrix:get subnets-matrix (row-index + 1) col-index
      inter-link-subnets subn1 subn2
      set row-index row-index + 1
    ]
    set col-index col-index + 1
    set row-index 0
  ]
end

; Given a set of nodes, moves them toward/away from the origin 
; by multipling coordinates by amount,
; which should be in (0,1) for shrinking, or > 1 for expansion.
to resize-network [nodes ratio]
  stretch-network nodes ratio ratio
end

; Given a set of nodes, stretches/shrinks in x and y dimensions by xratio and yratio, respectively.
to stretch-network [nodes xratio yratio]
  ask nodes [
    set xcor (clip-to-x-extrema (xratio * xcor))   ; note inner parens are essential
    set ycor (clip-to-y-extrema (yratio * ycor))]
end

; Given a set of nodes, moves them xratio of distance to right/left edge 
; and yratio up to the top/bottom edge (depending on whether xratio, yratio are positive or negative)
; ASSUMES that origin is in center, and that world is right-left and up/down symmetric (but not necess that height and width are same).
;to shift-network [nodes xratio yratio]
;  shift-network-by-patches nodes
;                           (xratio * max-pxcor)
;                           (yratio * max-pycor)
;end

; Given a set of nodes, moves them xincrement, yincrement patches to the right and up, respectively.
to shift-network-by-patches [nodes xincrement yincrement]
   ask nodes [set xcor (clip-to-x-extrema (xcor + xincrement))  ; note inner parens are essential
              set ycor (clip-to-y-extrema (ycor + yincrement))]
end

to-report clip-to-x-extrema [x]
  if x > max-pxcor [report max-pxcor]
  if x < min-pxcor [report min-pxcor]
  report x
end

to-report clip-to-y-extrema [y]
  if y > max-pycor [report max-pycor]
  if y < min-pycor [report min-pycor]
  report y
end

; start over with the same network
to reset-cultvars
  ask persons [setup-cultvar]
  clear-all-plots
  reset-ticks
  set ready-to-stop false
end

to setup-cultvar
  set activation ((random-float 2) - 1)
  set color (activn-to-color activation)
end

to toggle-degree-display
  if-else nodes-showing-numbers? [
    ask persons [set label ""]
    set nodes-showing-numbers? false
  ][
    ask persons [;set label sum [count link-neighbors] of link-neighbors
                 set label count link-neighbors 
                 set label-color ifelse-value (activation < .3) [black] [white]]
    set nodes-showing-numbers? true
  ]
end

to toggle-who-display
  if-else nodes-showing-numbers? [
    ask persons [set label ""]
    set nodes-showing-numbers? false
  ][
    ask persons [set label who 
                 set label-color ifelse-value (activation < .3) [black] [white]]
    set nodes-showing-numbers? true
  ]
end

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RUN

to go
  if (ready-to-stop) [
    set ready-to-stop false ; allows trying to restart, perhaps after altering parameters or network
    stop
  ]
  set stop-threshold 10 ^ stop-threshold-exponent ; allows changing this while running
  transmit-cultvars
  if (activns-settled) [set ready-to-stop true] ; compares activation with next-activation, so must run between transmit-cultvars and update-activns
  update-activns                                ; on the other hand, we do want to complete the activation updating process even if about to stop
  tick
end

to-report activns-settled
  let max-change (max [abs (activation - next-activation)] of persons) ; must be called between communication and updating activation
  report stop-threshold > max-change
end

; Transmit to any neighbor if probabilistic decide to transmit along that link.
; Probability is determined by activation value.
to transmit-cultvars
  ask persons
    [let message cultvar-to-message activation
     ask link-neighbors
       [if transmit-cultvar? message 
           [receive-cultvar message]]]
end

; Decide probabilistically whether to report your cultvar to an individual:
; Roughly, the absolute value of your activation is treated as a probability: When bias = 0,
; a random number between 0 and 1 is selected, and if your absolute activation is above that,
; you transmit to the receiver.  When bias is nonzero, the sum of activation and bias is used instead.
; i.e. for large activations, if bias has the same sign as activation, it increases the probability of
; transmission; if they have opposite signs, the probability is reduced. The result may be
; > 1, in which case the effect is the same as if it were 1.  For small absolute activations,
; adding bias to the activation may flip the sign and produce a number whose absolute value is
; larger than the absolute value of the activation. [IS THAT OK?]
to-report transmit-cultvar? [activn]
  report (abs (activn + prob-of-transmission-bias)) > (random-float 1)
end

to-report cultvar-to-message [activn]
  report activn
end

; RECEIVE-CULTVAR
; Let an incoming cultvar affect strength of receiver's cultvar.
; If incoming-activn is positive, it will move receiver's activn in that direction;
; if negative, it will push in negative direction. However, the degree of push will
; be scaled by how far the current activation is from the extremum in the direction
; of push.  If the distance is large, the incoming-activn will have a large effect.
; If the distance is small, then incoming-activn's effect will be small, so that it's
; harder to get to the extrema. The method used to do this is often used to update
; nodes in connectionist/neural networks (e.g. Holyoak & Thagard, Cognitive Science 13, 295-355 (1989), p. 313). 
to receive-cultvar [message]
  let incoming-activn (message-to-cultvar message)
  let candidate-activn (activation + (incoming-activn * (dist-from-extremum incoming-activn activation))) ; sign will come from incoming-activn; scaling factors are positive
  set next-activation max (list min-activn (min (list max-activn candidate-activn))) ; failsafe: cap at extrema. need list op, not [] here
end

to-report dist-from-extremum [incoming-activn current-activn]
  let dist ifelse-value (incoming-activn <= 0)
                        [activation - min-activn]  ; if incoming-activn is pushes in negative direction, get current distance from the min
                        [max-activn - activation] ; if incoming activen pushes in positive direction, get distance from max
  report max (list 1 dist)
end

; no scaling: trust is the incremental value, like in POPCO
to-report message-to-cultvar [activn]
  let sign sign-of activn
  report (sign * (random-normal trust-mean trust-stdev))
end


to update-activns
  ask persons
    [set activation next-activation
     set color (activn-to-color activation)
     if nodes-showing-numbers? [
       set label-color ifelse-value (activation < .3) [black] [white]]]
end


to make-activns-extreme
  ask persons
    [if-else activation >= 0
       [set activation 1
        set next-activation 1]
       [set activation -1
        set next-activation -1]
     set color (activn-to-color activation)]
end


to reset-colors
  ask persons
    [set color (activn-to-color activation)
     set label ""]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UTILITY PROCEDURES



; Finds middle-factors of n if there are factors > 1; otherwise returns middle-factors of n + 1.
to-report near-factors [n]
  if n = 1 [report [1 1]]  ; special case
  if n = 2 [report [2 1]]  ; special case
  let facs middle-factors n
  if-else (first facs) = 1 
    [report middle-factors (n + 1)]
    [report facs]
end

; Finds the pair of factors of n whose product is n and whose values are closest in value to each other.
to-report middle-factors [n]
  report middle-factors-helper n (floor (sqrt n))
end

to-report middle-factors-helper [n fac]
  ; if fac < 0, there's a bug, so let it error out in a stack overflow
  if fac = 0 [report (list 0 0)]
  if fac = 1 [report (list 1 n)]
  if (n mod fac) = 0 [report (list fac (n / fac))]
  report middle-factors-helper n (fac - 1)
end

to-report activn-to-color [activn]
  let zero-one-activn (activn + 1) / 2
  let zero-ten-activn round (10 * zero-one-activn)
  let almost-color netlogo-person-hue + 10 - zero-ten-activn   ; change "+ 10 -" to "+" to map colors in NetLogo order, not reverse
  report ifelse-value (almost-color = 10) [9.9] [almost-color]
end

to-report sign-of [x]
  report ifelse-value (x >= 0) [1] [-1]
end

; NetLogo's standard-deviation and variance are sample functions, i.e. dividing 
; by n-1 rather than n.
; These functions undo the sample correction to give a proper population variance and 

to-report var [lis]
  let n length lis
  report (variance lis) * (n - 1) / n
end

to-report stdev [lis]
  report sqrt (var lis)
end

to yo
  let counts [] 
  foreach (sort turtles) [
    set counts lput ([count link-neighbors] of ?) counts
  ]
  show counts
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
810
631
29
29
10.0
1
9
1
1
1
0
0
0
1
-29
29
-29
29
1
1
1
ticks
30.0

BUTTON
0
10
95
43
set up network
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
0
335
56
369
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
815
130
1025
250
average cultvar activations
time
activn
0.0
52.0
-1.0
1.0
true
true
"" ""
PENS
"Bl" 1.0 0 -16777216 true "" "plot (mean [ifelse-value (activation > 0) [activation] [0]] of persons)"
"Wh" 1.0 0 -5987164 true "" "plot (mean [ifelse-value (activation < 0) [activation] [0]] of persons)"
"pop" 1.0 0 -8053223 true "" "plot (mean [activation] of persons)"

SLIDER
0
105
170
138
nodes-per-subnet
nodes-per-subnet
4
1000
200
1
1
NIL
HORIZONTAL

SLIDER
0
140
170
173
average-node-degree
average-node-degree
1
min (list 500 (nodes-per-subnet - 1))
15
1
1
NIL
HORIZONTAL

BUTTON
55
335
119
369
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
10
185
43
NIL
reset-cultvars
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
814
9
1024
129
cultvar freqs & pop variance
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Bl" 1.0 0 -16777216 true "" "plot ((count persons with [activation > 0])/(count persons))"
"Wh" 1.0 0 -5987164 true "" "plot ((count persons with [activation < 0])/(count persons))"
"var" 1.0 0 -8053223 true "" "plot (var [activation] of persons)"

SLIDER
0
390
205
423
trust-mean
trust-mean
.01
1
0.05
.01
1
NIL
HORIZONTAL

SLIDER
0
475
205
508
prob-of-transmission-bias
prob-of-transmission-bias
-1
1
0
.02
1
NIL
HORIZONTAL

TEXTBOX
175
460
212
480
black
10
0.0
1

TEXTBOX
5
460
35
480
white
10
0.0
1

SLIDER
0
425
205
458
trust-stdev
trust-stdev
0
.1
0
.01
1
NIL
HORIZONTAL

PLOT
815
250
1025
390
degree distribution
degree
# of nodes
1.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "let max-degree max [count link-neighbors] of persons\nplot-pen-reset  ;; erase what we plotted before\nset-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\nhistogram [count link-neighbors] of persons" "let max-degree max [count link-neighbors] of persons\nplot-pen-reset  ;; erase what we plotted before\nset-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\nhistogram [count link-neighbors] of persons"

SLIDER
0
173
170
206
number-of-subnets
number-of-subnets
1
20
1
1
1
NIL
HORIZONTAL

SLIDER
0
255
170
288
inter-nodes-per-subnet
inter-nodes-per-subnet
0
10
4
1
1
NIL
HORIZONTAL

CHOOSER
0
210
93
255
subnet1
subnet1
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
0

CHOOSER
93
210
185
255
subnet2
subnet2
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
1

BUTTON
0
291
55
324
link-em
inter-link-subnets subnet1 subnet2\n; subnet1 and subnet2 are globals defined\n; by gui elements.
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
545
203
578
stop-threshold-exponent
stop-threshold-exponent
-20
0
-3
1
1
NIL
HORIZONTAL

TEXTBOX
5
580
204
623
Iteration stops if max activn change is < 10 ^ stop-threshold-exponent.  Less negative means stop sooner.
11
0.0
1

BUTTON
0
45
85
78
extremize
make-activns-extreme
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
55
290
164
324
NIL
link-near-subnets
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
5
85
105
103
network structure:
11
0.0
1

TEXTBOX
0
375
140
393
transmission parameters:
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model of spread of conflicting beliefs or other cultural variants on a network.  It allows experimenting with the effect of different network structures and transmission biases on the distribution of beliefs. The model suggests that for some forms of cultural transmission, network structure can affect whether cultural variation can be maintained on reasonable time scales.

## HOW IT WORKS

Each person (node) has a degree of confidence.  1 indicates full confidence in the "black" proposition.  -1 indicates full confidence in its negation.  Degrees of confidence are not transmitted.  Instead, the degree of confidence (activation) determines the probability that a belief will be communicated.  (After all, when people offer assertions to each other, they don't generally indicate their degree of confidence, even if there are ways to do that by choice of words and tone of voice.)

On each tick, for each link attached to a person, the person randomly decides to "utter" the proposition to its (undirected) network neighbors, with probability equal to the absolute value of the degree of confidence plus prob-of-transmission-bias.  The value that's conveyed to the receiver of the utterance is trust-mean times the sign of the original degree of confidence, or a Normally distributed value with mean trust-mean and standard deviation trust-stdev, if trust-stdev is not zero.  The effect of this input to the receiver's degree of confidence depends on how far the latter is from -1 or 1.

If the activation coming into a node is positive, it will move receiver's activation in that direction; if negative, it will push in negative direction. However, the degree of push will be scaled by how far the current activation is from the extremum in the direction of push.  If the distance is large, the incoming activation will have a large effect. If the distance is small, then incoming-activn's effect will be small, so that it's harder to get to the extrema. The method used to do this is often used to update nodes in connectionist/neural networks.  Note that this is not Bayesian updating.

You can create multiple "subnetworks" which will be unconnected unless you create "inter-links" between them.  Inter-links are a different color than within-subnet links, but all links function identically.  Similarly, nodes connected to inter-links change shape, but this does not change their functioning.

Each subnetwork is created randomly in order to make the total number of links such that the average node degree per node is that specified by the user.  However, the network-creation algorithm tries to link to nodes which are located near each other.  This means that the node chosen for linking is random, since locations are random.  However, the result is not an Erdos-Renyi binomial/Possion network, since pairs of nodes don't have equal probability of being linked: Closer nodes are overwhelmingly more likely to be linked.

## HOW TO USE IT

Most of the GUI controls should be easy to understand with a little bit of experimentation.  

The inter-nodes and inter-links controls are used to add links between subnets which otherwise would be unconnected.  inter-nodes-per-subnet determines the number of nodes in subnet1 and subnet2 that will be connected to each other each time create-inter-links is pushed.  When the button is pushed, each of the "inter-nodes" from subnet1 is linked to each of the inter-nodes from subnet2.  (If you want to create singly linked inter-nodes instead, set inter-nodes-per-subnet to 1, and push the button as many times
as needed.)


## THINGS TO NOTICE

The spread of black or white beliefs is influenced by how well connected different nodes are.  A set of nodes with many interconnections can reinforce similarity among its members, even in the face of a bias toward an alternative cultural variant.

If a group of nodes has more connections to each other than to "outsiders", it can
maintain an extreme view even if surrounded by those with the opposite view.

## THINGS TO TRY

Start with average node degree in the range of 12 to 15.  Does one color take over the network? Once the network has stopped, or you have stopped it, try clicking "reset-cultvars". The network will be preserved, but the nodes will be given a different set of random beliefs.  What happens this time?  What if you run it many times with the same network structure?

Now try increasing the average node degree to 20, or 30.  Perform the same experiment. What happens?

Go back to your original node degree and run the model until there is a stable pattern.  Now change prob-of-transmission-bias, making the black (1) or white (-1) cultural variant more likely to be transmitted.  What happens?  Is it possible to maintain cultural variation with a nonzero value for this parameter?

Try altering trust-mean or trust-stdev.  What happens?  

Try creating multiple subnetworks.  You can link them using the "link-em" or "link-near-subnets" buttons.  (Experiment with the settings above those buttons.)  Under what conditions can both black and white be preserved on the network?
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

dashed
0.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
