; NetworkExperiment6.nlogo
; THIS VERSION CREATES TWO SUBNETS WITH A SINGLE LINK BETWEEN THEM
; Marshall Abrams' based on:
;
; Stonedahl, F. and Wilensky, U. (2008). NetLogo Virus on a Network model. 
; http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork. 
; Center for Connected Learning and Computer-Based Modeling, 
; Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

; Globals set by user:
;   trust-mean
;   number-of-nodes
;   average-node-degree
;   stop-if-no-change-exponent
;   probability-of-transmitting
  
globals
[
  max-activn
  min-activn
  stop-threshold
  ready-to-stop
  netlogo-turtle-hue
  link-color
  background-color
]

turtles-own
[
  activation  ; ranges from min-activn to max-activn
  next-activation  ; allows parallel updating
  node-subnet
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
  
  set max-activn 1
  set min-activn -1
  set stop-threshold 10 ^ (-1 * stop-if-no-change-exponent)
  ;set probability-of-transmitting .5
  
  ;set background-color 73 ; a blue-green
  set background-color 17 ; peach
  ;set background-color 58
  set netlogo-turtle-hue 0
  set link-color 123

  ask patches [set pcolor background-color]
  create-nodes 1
  create-nodes 2
  create-network 1
  create-network 2
  ask one-of turtles with [node-subnet = 1] [
    create-link-with one-of turtles with [node-subnet = 2]
    ;ask link-with one-of turtles with [node-subnet = 2] [ set color yellow ]
  ]

  layout-network

  reset-ticks
end

to create-nodes [subn]
  set-default-shape turtles "circle"
  crt number-of-nodes
  [
    set node-subnet subn
    ; for visual reasons, we don't put any nodes *too* close to the edges
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    setup-cultvar
  ] 
end

; start over with the same network
to reset-cultvars
  ask turtles [setup-cultvar]
  clear-all-plots
  reset-ticks
  set ready-to-stop false
end

; mostly from "Virus on a Network"--see above
; Assign a random number of links randomly between pairs of nodes, making the total number of links such
; that the average node degree per node is that specified by the user.
; Algorithm:
; Keep doing the following until you've created enough links that you have average-node-degree/2 per node:
; ( /2 since each link adds a degree to two nodes)
; Choose a random turtle, and create a link to the physically closest turtle to which it's not already linked.
; Since create-nodes gave turtles random locations, the link is to a random turtle.
; (Note that these locations will be revised by layout-network.  Their only function is to group turtles
; randomly--in effect to randomly order turtles by closeness to any given turtle.)
to create-network [subn]
  let num-links (average-node-degree * number-of-nodes) / 2
  while [count links with [link-subnet = subn] < num-links ]
  [
    ask one-of turtles with [node-subnet = subn]
    [
      let choice (min-one-of (other turtles with [node-subnet = subn and not link-neighbor? myself]) [distance myself])
      if choice != nobody [ create-link-with choice ]
      ask link-with choice [set link-subnet subn]
    ]
  ]
  ask links [ set color link-color ]
end

to layout-network
  repeat 100
  [
    layout-spring turtles links 0.1 (world-width / (sqrt number-of-nodes)) 1 ; 3rd arg was 0.3 originally
  ]
end

to setup-cultvar
  set activation ((random-float 2) - 1)
  set color (activn-to-color activation)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RUN

to go
  if (ready-to-stop) [stop]
  transmit-cultvars
  if (activns-settled) [set ready-to-stop true] ; compares activation with next-activation, so must run between transmit-cultvars and update-activns
  update-activns                                ; on the other hand, we do want to complete the activation updating process even if about to stop
  tick
end

to-report activns-settled
  let max-change (max [abs (activation - next-activation)] of turtles) ; must be called between communication and updating activation
  report stop-threshold > max-change
end

to transmit-cultvars
  ask turtles
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
  ask turtles
    [set activation next-activation
     set color (activn-to-color activation)]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UTILITY PROCEDURES

to-report activn-to-color [activn]
  let zero-one-activn (activn + 1) / 2
  let zero-ten-activn round (10 * zero-one-activn)
  let almost-color netlogo-turtle-hue + 10 - zero-ten-activn   ; change "+ 10 -" to "+" to map colors in NetLogo order, not reverse
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

; standard deviation. Varely different for reasonable number of nodes, but still ....
;to-report stdev [lis]
;  report  sqrt (var lis)
;end
@#$#@#$#@
GRAPHICS-WINDOW
287
13
968
715
30
30
11.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
46
205
102
239
NIL
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
170
205
226
239
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
14
424
268
544
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
"Bl" 1.0 0 -16777216 true "" "plot (mean [ifelse-value (activation > 0) [activation] [0]] of turtles)"
"Wh" 1.0 0 -5987164 true "" "plot (mean [ifelse-value (activation < 0) [activation] [0]] of turtles)"
"pop" 1.0 0 -8053223 true "" "plot (mean [activation] of turtles)"

SLIDER
39
12
247
45
number-of-nodes
number-of-nodes
10
1000
100
5
1
NIL
HORIZONTAL

SLIDER
39
47
248
80
average-node-degree
average-node-degree
1
min (list 50 (number-of-nodes - 1))
10
1
1
NIL
HORIZONTAL

BUTTON
104
205
168
239
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

SLIDER
37
549
245
582
stop-if-no-change-exponent
stop-if-no-change-exponent
1
10
3
1
1
NIL
HORIZONTAL

BUTTON
46
243
162
277
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

TEXTBOX
167
248
262
282
<- start over\nwith same net.
11
0.0
1

PLOT
13
302
267
422
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
"Bl" 1.0 0 -16777216 true "" "plot ((count turtles with [activation > 0])/(count turtles))"
"Wh" 1.0 0 -5987164 true "" "plot ((count turtles with [activation < 0])/(count turtles))"
"var" 1.0 0 -8053223 true "" "plot (var [activation] of turtles)"

SLIDER
39
83
247
116
trust-mean
trust-mean
.01
1
0.96
.01
1
NIL
HORIZONTAL

SLIDER
39
153
248
186
prob-of-transmission-bias
prob-of-transmission-bias
-1
1
0
.01
1
NIL
HORIZONTAL

TEXTBOX
253
165
290
185
black
10
0.0
1

TEXTBOX
6
166
42
186
white
10
0.0
1

SLIDER
39
118
248
151
trust-stdev
trust-stdev
0
.1
0
.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the spread of a virus through a network.  Although the model is somewhat abstract, one interpretation is that each node represents a computer, and we are modeling the progress of a computer virus (or worm) through this network.  Each node may be in one of three states:  susceptible, infected, or resistant.  In the academic literature such a model is sometimes referred to as an SIR model for epidemics.

## HOW IT WORKS

Each time step (tick), each infected node (colored red) attempts to infect all of its neighbors.  Susceptible neighbors (colored green) will be infected with a probability given by the VIRUS-SPREAD-CHANCE slider.  This might correspond to the probability that someone on the susceptible system actually executes the infected email attachment.  
Resistant nodes (colored gray) cannot be infected.  This might correspond to up-to-date antivirus software and security patches that make a computer immune to this particular virus.

Infected nodes are not immediately aware that they are infected.  Only every so often (determined by the VIRUS-CHECK-FREQUENCY slider) do the nodes check whether they are infected by a virus.  This might correspond to a regularly scheduled virus-scan procedure, or simply a human noticing something fishy about how the computer is behaving.  When the virus has been detected, there is a probability that the virus will be removed (determined by the RECOVERY-CHANCE slider).

If a node does recover, there is some probability that it will become resistant to this virus in the future (given by the GAIN-RESISTANCE-CHANCE slider).

When a node becomes resistant, the links between it and its neighbors are darkened, since they are no longer possible vectors for spreading the virus.

## HOW TO USE IT

Using the sliders, choose the NUMBER-OF-NODES and the AVERAGE-NODE-DEGREE (average number of links coming out of each node).

The network that is created is based on proximity (Euclidean distance) between nodes.  A node is randomly chosen and connected to the nearest node that it is not already connected to.  This process is repeated until the network has the correct number of links to give the specified average node degree.

The INITIAL-OUTBREAK-SIZE slider determines how many of the nodes will start the simulation infected with the virus.

Then press SETUP to create the network.  Press GO to run the model.  The model will stop running once the virus has completely died out.

The VIRUS-SPREAD-CHANCE, VIRUS-CHECK-FREQUENCY, RECOVERY-CHANCE, and GAIN-RESISTANCE-CHANCE sliders (discussed in "How it Works" above) can be adjusted before pressing GO, or while the model is running.

The NETWORK STATUS plot shows the number of nodes in each state (S, I, R) over time.

## THINGS TO NOTICE

At the end of the run, after the virus has died out, some nodes are still susceptible, while others have become immune.  What is the ratio of the number of immune nodes to the number of susceptible nodes?  How is this affected by changing the AVERAGE-NODE-DEGREE of the network?

## THINGS TO TRY

Set GAIN-RESISTANCE-CHANCE to 0%.  Under what conditions will the virus still die out?   How long does it take?  What conditions are required for the virus to live?  If the RECOVERY-CHANCE is bigger than 0, even if the VIRUS-SPREAD-CHANCE is high, do you think that if you could run the model forever, the virus could stay alive?

## EXTENDING THE MODEL

The real computer networks on which viruses spread are generally not based on spatial proximity, like the networks found in this model.  Real computer networks are more often found to exhibit a "scale-free" link-degree distribution, somewhat similar to networks created using the Preferential Attachment model.  Try experimenting with various alternative network structures, and see how the behavior of the virus differs.

Suppose the virus is spreading by emailing itself out to everyone in the computer's address book.  Since being in someone's address book is not a symmetric relationship, change this model to use directed links instead of undirected links.

Can you model multiple viruses at the same time?  How would they interact?  Sometimes if a computer has a piece of malware installed, it is more vulnerable to being infected by more malware.

Try making a model similar to this one, but where the virus has the ability to mutate itself.  Such self-modifying viruses are a considerable threat to computer security, since traditional methods of virus signature identification may not work against them.  In your model, nodes that become immune may be reinfected if the virus has mutated to become significantly different than the variant that originally infected the node.

## RELATED MODELS

Virus, Disease, Preferential Attachment, Diffusion on a Directed Network

## NETLOGO FEATURES

Links are used for modeling the network.  The `layout-spring` primitive is used to position the nodes and links such that the structure of the network is visually clear.


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
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

@#$#@#$#@
1
@#$#@#$#@
