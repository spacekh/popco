; HTsOriginalSocratesForPOPCO.lisp
; THIS VERSION BYPASSES THE POPCO LOOP.

; Attempt to recreate original Socrates example from Holyoak and Thagard 1989.
; (It's not really H&T's original code--I don't have this.  It's my reconstruction
; based on the article.)
; POPCO version:
; embedding each analogy in a single person (which does not engage in communication).

; NOTE: HT1989params.lisp should usually be loaded first.

;*************************
(SETF *DONT-CONVERSE* T)            ; don't allow people to converse
(SETF *DONT-UPDATE-PROPN-NETS* T)   ; don't create proposition nets--only ACME nets
(SETF *MAX-GENERATIONS* 1)           ; run only one generation, with
(SETF *MAX-TIMES* 300)              ; sufficient cycles to allow setlting
;; or:
;(SETF *MAX-TIMES* 1)                ; run one net cycle per generation, with
;(SETF *MAX-GENERATION* 150)         ; sufficient generations to allow settling
;(SETF *SILENT-RUN?* nil)          ; suppress general verbose reporting 
;(SETF *SILENT-RUN?* t)          ; enable general verbose reporting 
(SETF *REPORT-ACTIVN-CHANGE* t) ; report average change in activations of units
(SETF *ASYMPTOTE* .0001) ; traditional value
(SETF *ASYMPTOTE* .001)
;*************************

;; first clear everything out
(mapcar #'clear-plists (get 'citizens 'members))
(clear-person-nets 'citizens)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; We define a few lists of proposition messages, which can be reused
; in various ways in different persons:

; target propositions--intended analog of midwife analog:
(defvar iso-soc-propns
      '((philosopher (Socrates) s1)
        (student (obj-student) s2) 
        (intellectual-partner (obj-partner) s3) 
        (idea (obj-idea) s4) 
        (introduce (Socrates obj-student obj-partner) s5) 
        (formulates (obj-student obj-idea) s6) 
        (cause (s5 s6) s7) 
        (thinks-about (obj-student obj-idea) s8) 
        (tests-truth (obj-student obj-idea) s9) 
        (helps (Socrates obj-student) s10) 
        (knows-truth-or-falsity (obj-student obj-idea) s11) 
        (cause (s10 s11) s12)))

; more target propositions--possible but not intended analogs:
(defvar noniso-soc-propns
      '((father (Socrates) s20) 
        (poison (obj-hemlock) s21) 
        (drink (Socrates obj-hemlock) s22) 
        (midwife (obj-soc-midwife) s23) 
        (mother (obj-soc-wife) s24) 
        (matches (obj-soc-midwife obj-soc-wife Socrates) s25) 
        (child (obj-soc-child) s26) 
        (conceives (obj-soc-wife obj-soc-child) s27) 
        (cause (s25 s27) s28) 
        (in-labor-with (obj-soc-wife obj-soc-child) s29) 
        (helps (obj-soc-midwife obj-soc-wife) s30) 
        (give-birth-to (obj-soc-wife obj-soc-child) s31) 
        (cause (s30 s31) s32)))

; both sets of target propositions together make up the nonisomorphic analog:
(defvar all-soc-propns (append iso-soc-propns noniso-soc-propns))

; source analog propositions:
(defvar midwife-propns
  '((midwife (obj-midwife) m1)
    (mother (obj-mother) m2)
    (father (obj-father) m3)
    (child (obj-child) m4)
    (matches (obj-midwife obj-mother obj-father) m5)
    (conceives (obj-mother obj-child) m6)
    (cause (m5 m6) m7)
    (in-labor-with (obj-mother obj-child) m8)
    (helps (obj-midwife obj-mother) m10)
    (give-birth-to (obj-mother obj-child) m11)
    (cause (m10 m11) m12)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; make the persons

; the isomporphic analogy
(make-person
  'iso 'citizens '()
  '((make-struc 'target 'problem `(start (,@iso-soc-propns)))
    (make-struc 'source 'problem `(start (,@midwife-propns)))))

; the bare nonisomporphic analogy
(make-person
  'non 'citizens '()
  '((make-struc 'target 'problem `(start (,@all-soc-propns)))
    (make-struc 'source 'problem `(start (,@midwife-propns)))))

; the nonisomporphic analogy with pragmatic enhancement
(make-person
  'prag 'citizens '()
  '((make-struc 'target 'problem `(start (,@all-soc-propns)))
    (make-struc 'source 'problem `(start (,@midwife-propns)))
    (presumed '(s1=m1 socrates=obj-midwife philosopher=midwife))) ; see p. 347
  '((important '(s4 idea obj-idea)))) ; goes in person's field 'addl-input.  Also from p. 347.

(load "a/HTsOriginalSocratesForPOPCOutilities")

(format t "Creating networks...~%")
(create-nets 'citizens)
(format t "Settling networks, ~S cycles per generation in ~S generation(s) ...~%" *max-times* *max-generations*)
(mapc #'settle-net (get 'citizens 'members))

(print-values)

