
    (cond ((member personal-propn (get personal-struc 'propositions)) nil)
          (t (setf (get listener 'settled?) nil) ; if net had settled, a new propn makes it unsettled
             (add-struc personal-struc           ; add the proposition to the analog
                        'start
                        (list (get proposition 'message)))
             t))))

;; helper function for receive-utterance
;; Assumes that receive-utterance has set *the-person* to listener
;(defun receive-propn-in-struc (generic-propn personal-struc)
;  (setf (get listener 'settled?) nil) ; if net had settled, a new propn makes it unsettled
;  (add-struc personal-struc           ; add the proposition to the analog structure
;             'start
;             (list (get generic-propn 'message))))


(defun choose-utterance (conversepair)
  (let ((speaker-thoughts (get (speaker-of-cpair conversepair) 'all-propositions))) ; IS THIS RIGHT? CAN MOVE TARGET PROPS TO SOURCE ANALOGS
    (cons
      (choose-thought speaker-thoughts)
      conversepair)))


;; EXPERIMENT: FAILS because fmt-list-string-for-netlogo, unlike fmt-tree-for-netlogo, does not replace nil with "[]".
;; [Needs to be redone with regexps.] [Actually some Lisps--sbcl, clisp--pretty-print output by default. Just let them....]
;(defun pretty-report-persons (population) 
;  (princ 
;    (fmt-list-string-for-netlogo
;      (with-output-to-string (s)
;        (pprint (mapcar #'fmt-person-for-netlogo (get population 'members)) s)))
;    *ui-outstream*)
;  (terpri *ui-outstream*))

; PERCEIVED - OLD LINK-BASED VERSION
; NOTE: Arg is a *personal* propn.
; This is automatically called on every node listed in given-el, i.e.
; the third argument to make-person. 
; The effect of this is similar to the function DATA in echo.lisp.
; In a sense I'm duplicating code.  However, I want to simplify and separate 
; out this functionality from the world of ECHO for now.  Maybe need to integrate
; it later.  Also, it's clearer in graphical displays of networks to 
; have a different special node for environmental inputs and semantic emphasis.
; I'm also just making this simple function.  You can mapc it over a list
; of proposition units if you want conciseness.
;(defun perceived (propn &optional (degree 1))
;  (make-sym-link 'salient propn (* degree *perceived-excit*)))
; TODO: Question: Should this be changed to raw make-link calls to avoid summing if called repeatedly?

; UNPERCEIVED
; DISABLED since designed to work with the old PERCEIVED function which created links,
; rather than the new PERCEIVED function which causes the environment to talk to the person.
; Intended to remove the property of being perceived.
; NOTE: Arg is a *personal* propn.
; IMPORTANT NOTES: 
; - If the salient link has been unaffected by conversation, and if it's
;   equal to *perceived-excit*, the link is set to zero.
; - There is no floor.  If conversation has lowered the link weight,
;   this operation could make the link weight to salient negative.
; - If the link weight was at a maximum, the effects of positive
;   utterances which would have pushed above the max will have been 
;   forgotten.  As a result, this function could push the link weight
;   down below what it properly should be. This is a bug, strictly speaking.
;(defun unperceived (propn)
;  (set-sym-link-weight propn 'salient 
;                       (- (weight-of-link-between propn 'salient)
;                                         *perceived-excit*)))

; make/update proposition links from proposition-map-units
(defun update-proposition-net (person)
  (when *do-update-propn-nets*
    (setf *the-person* person) ; [redund if called from create-net]
    (mapc #'update-assoc-from-unit (get *the-person* 'propn-map-units)) ; from acme-infer.lisp
    (mapc #'update-semantic-iff (get *the-person* 'semantic-iffs))))

;; IS THIS RIGHT??
; sem-iff-spec has the form (propn-unit1 propn-unit2 weight)
(defun update-semantic-iff (sem-iff-spec)
  (format t "~%UPDATE-SEMANTIC-IFF still being called but shouldn't be.~%")
  (apply #'make-sym-link-if-units sem-iff-spec))


;(defun invoke-semantic-iffs-for-person (person)
;  (mapc #'apply-raw-make-symlink-if-units (get person 'semantic-iffs)))
;
;(defun invoke-semantic-iffs-for-pop (population)
;  (mapc #'invoke-semantic-iffs-for-person (get population 'members)))

(defun time-to-stop ()
  (or 
    (and (> *max-pop-ticks* 0)
         (>= *pop-tick* *max-pop-ticks*))
    (user-says-stop)))

; PERCEIVED-NEGATION
; Perceive a propn.  Insert the proposition into a person's "external" 
; environment, setting its activation to -1.
; ARG: a proposition message, i.e. a full subject/predicate representation in list form.
; OR: For convenience, this can now be passed a proposition name symbol
; AND you can pass either a personal or generic proposition symbol
; Note that PERCEIVED has none of this flexibility, nor should it, probably.
; The idea is that while PERCEIVED is designed for use in internal code, PERCEIVED-NEGATION
; is designed for interactive use.  But still:
; THIS KLUDGINESS SHOULD BE CLEANED UP AT SOME POINT.
; *THE-PERSON* MUST BE SET CORRECTLY.
(defun perceived-negation (propn &optional (person *the-person*))
  (cond ((consp propn)
         (perceived msg -1 person))
        ((symbolp propn)
         (perceived 
           (get (maybe-depersonalize-sym propn) 'message)
           -1
           person))
        (t (error "perceived-negation: ~S is neither a symbol nor a list." propn))))

; OLD CODE FORMERLY IN UPDATE-NET:
    ; old two-analog version of the constraint-map calls:
    ; (constraint-map (generic-to-personal-sym 'target)
    ;                 (generic-to-personal-sym 'source))

    ; The following code used to appear in update-analogy-net after the double mapc ... constraint-map ... form,
    ;  near the end of update-analogy-net, but it's only needed on demand, not in every pop-tick.
    ; [Taking it out makes a big difference in abcl--shaves off 1/3 of the time in one test--but doesn't
    ;  seem to matter for sbcl or ccl--Maybe they were compiling it away since nothing used it?]
    ;(setf *weight-of-all-constraints* (sum-constraints)) ; only used in coh-score; maybe delete
    ;(setf (get *the-person* 'all-constraints) 
    ;      (list-constraints (get *the-person* 'all-units))) ; useful to have record of constraints in person


; RAW-MAKE-SYMLINK-IF-UNITS
;; Make symlink if the two units to be linked are suitable--if they
;; have activation values.  Silently returns nil if not.
(defun record-raw-make-symlink-if-units (unit1 unit2 weight)
  (when (and (unit? unit1)
             (unit? unit2))
    (mark-constraint-newly-added unit1 unit2 weight *the-person*) ; record that we're making a new constraint, so popco can tell gui if desired
    ;(format t "about to call (raw-symlink ~S ~S ~S)~%" unit1 unit2 weight)
    (raw-make-symlink unit1 unit2 weight))) ; from network.lisp

; APPLY-RAW-MAKE-SYMLINK-IF-UNITS
(defun apply-record-raw-make-symlink-if-units (unit1-unit2-weight-list)
  ;(format t "~%apply-record-raw-make-symlink-if-units ~S ...~%" unit1-unit2-weight-list) ; DEBUG
  ;(format t "~S: ~S, ~S: ~S~%" (car unit1-unit2-weight-list) (unit? (car unit1-unit2-weight-list)) (cadr unit1-unit2-weight-list) (unit? (cadr unit1-unit2-weight-list)))
  (apply #'record-raw-make-symlink-if-units unit1-unit2-weight-list))

