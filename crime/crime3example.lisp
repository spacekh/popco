;;;; originally was: dispersal1.lisp
;;;; (similar to crime3socnet1.lisp)
;;;; four distinct subpops who don't communicate with each other, 
;;;; but have different biases, and listen to the same pundit.

(load "nosettle")      ; don't allow networks to settle, ever, since subtle differences are amplified by communication
(load "crime/crime3")

(setf *do-report-to-netlogo* nil)
(setf *do-report-propns-to-csv* t)

(setf *DO-UPDATE-PROPN-NETS-FROM-PROPN-NETS* NIL)

;(defvar *group-size* 25)

; don't move graph around in telguess:
(setf *guess-layout-commands* "")
(setf *extra-meta-commands* "")
(setf *do-converse* nil)

;(make-no-bias-crime-talker 'aa crime-propns 'pundits '(VIBIs BEBIs BOBIs NOBIs))  ; pundit

;(make-virus-bias-crime-talker 'temp-vi '() 'vibis '(vibis))
;(n-persons-with-name 'temp-vi 'vi *group-size*)
;(kill 'temp-vi)

;(make-beast-bias-crime-talker 'temp-be '() 'bebis '(bebis))
;(n-persons-with-name 'temp-be 'be *group-size*)
;(kill 'temp-be)

;(make-both-bias-crime-talker 'temp-bo '() 'bobis '(bobis))
;(n-persons-with-name 'temp-bo 'bo *group-size*)
;(kill 'temp-bo)

(make-both-bias-crime-talker  'bo '() 'folks '(folks))
(make-beast-bias-crime-talker 'be '() 'folks '(folks))
(make-virus-bias-crime-talker 'bv '() 'folks '(folks))

; Add a person with a sets of propositions
;            name groups given
;(make-person 'hal 'folks '() 
;             `((make-struc 'target 'problem '(start (,@viral-crime-propns)))
;               (make-struc 'source 'problem '(start (,@virus-propns)))
;               ,@semantic-relations)
;             '()          ; addl-input
;             '(target)    ; converse-strucs
;             '() ; talks-to
;             1)   ;num-listeners (may be irrelev)

;(make-no-bias-crime-talker 'temp-no '() 'nobis '(nobis))
;(n-persons-with-name 'temp-no 'no *group-size*)
;(kill 'temp-no)


(setf *max-pop-ticks* 100)
(init-pop)
(print (get 'folks 'members))

;(gc :full t) ; garbage collect first for greater uniformity in time trials
(popco)
;(quit)
