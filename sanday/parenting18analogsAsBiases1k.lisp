;; parenting18analogsAsBiases1k.lisp
;; uses/applies code in parenting18analogsAsBiases1.lisp (q.v. for outline of purpose, etc.)

; Make a pop of people who only talk about lifestyle propns (any of them)
; and whose origin propns are only sky propns, where one person is the only
; initial perceiver (of all lifestyle propns) who then communicates them to
; others.  I'm hoping this will allow the origin analogs to affect community
; beliefs by in effect reducing the effect of perceptions by making them
; filter from one person.  QUESTION: IS EFFECT OF UTTERANCE PARAMETER SET
; OPTIMALLY?  REMEMBER THAT UTTERANCES IN EFFECT CREATE PERCEPTIONS.

(load "sanday/parenting18analogsAsBiases1")

(defvar *my-pop-size* 10)

; don't move graph around in telguess:
(setf *guess-layout-commands* "")
(setf *extra-meta-commands* "")
(setf *do-converse* t)

(make-originless-lifestyle-talker 'temp-person)
(n-persons-with-name 'temp-person 's (1- *my-pop-size*)) ; "s" for sky-based
(rem-elt-from-property 'temp-person 'folks 'members)
(make-originless-lifestyle-talker 'sp lifestyle-propns) ; "sp" for sky-based perceiver

(init-pop)
(print (get 'folks 'members))

(setf *max-pop-ticks* 1500)
(popco)
