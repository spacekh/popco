;;; crime3propnsRepurposed.lisp
;;; Revised comments on propositions, treating them as about carnivores and herbivores rather than beasts and viruses

;; NOTE THIS CONCERNS DISEASE TRANSMISSION. "VIRUS" IS NOT ESSENTIAL.  IT COULD AS WELL BE EVIL SPIRITS.
(defvar virus-propns
  '(
    (is-infected (vpers-0) v-ip)              ; Person 0 has infection.
    (not-infected (vpers-1) v-na)             ; Person 1 lacks infection.
    (is-infected (vpers-1) v-ia)              ; Person 1 has infection.
    (harms (vpers-1) v-ha)                    ; Person 1 is harmed.
    (cause (v-ia v-ha) v-ci->ha)              ; That person 1 has infection is harmful to person 1. [HO1]
    (infect (vpers-0 pers-1) v-ipa)           ; Person 0, who already has infection, infects person 1.
    (cause (v-ipa v-ia) v-ipa->ia)            ; The infecting of person 1 by person 0 causes person 1 to have infection. [HO1]
    (inoculate (vpers-1) v-ica)               ; Person 1 gets preventative methods applied, etc., is isolated, etc.
    (prevent (v-ica v-ipa) v-ia->-spa)        ; That person 1 has preventative methods applied prevents person 0 from infecting person 1. [HO1]
    (cause (v-ia->-spa v-na) v-iaspa->na)     ; That the preventative appliction to 1 prevents the infecting, causes [preserves] person 1 lacking infection. [HO2]
    (quarantine (vpers-0) v-qp)               ; Person 0 is quarantined.
    (prevent (v-qp v-ipa) v-qp->-spa)         ; That person 0 is quarantined prevents person 0 from infecting person 1.
    (cause (v-qp->-spa  v-na) v-qpspa->na)    ; That (quarantining 0 prevents 0 from infecting 1) causes [preserves] person 1 lacking infection. [HO2]
   ))

(defvar viral-crime-propns
  '(
    (is-criminal (cpers-0) cv-cp)             ; Garden 0 has been attacked by pests.
    (not-criminal (cpers-1) cv-na)            ; Garden 1 has not been attacked by pests.
    (is-criminal (cpers-1) cv-ca)             ; Garden 1 has been attacked by pests.
    (harms (cpers-1) cv-ha)                   ; Garden 1 is harmed.
    (cause (cv-ca cv-ha) cv-ca->hp)           ; Garden 1 being attacked by pests is harmful to garden 1.
    (recruit (cpers-0 cpers-1) cv-rpa)        ; Pests move from garden 0 to garden 1.
    (cause (cv-rpa cv-ca) cv-sca->ca)         ; Pests moving from garden 0 to garden 1 causes garden 1 to be attacked. [HO1]
    (support (cpers-1) cv-sa)                 ; Garden 1 is protected by fertilizer, substances noxious to pests, fences, etc.
    (prevent (cv-sa cv-rpa) cv-sa->-rpa)      ; Garden 1 being protected prevents pests from moving from garden 0 to garden 1. [HO1]
    (cause (cv-sa->-rpa cv-na) cv-sarpa->na)  ; That garden 1 is protected pests from moving from 0 to 1 causes [preserves] 1's health. [HO2]
    (imprison (cpers-0) cv-ip)                ; Garden 0 is isolated by fences, etc.
    (prevent (cv-ip cv-rpa) cv-ip->-rpa)      ; Garden 0 being isolated prevents pests from moving from garden 0 to garden 1. [HO1]
    (cause (cv-ip->-rpa  cv-na) cv-iprpa->na) ; That O's isolation prevents pests from moving from 0 to 1 causes [preserves] 1's health. [HO2]
   ))

(defvar beast-propns
  '(
    (human (bpers) b-pp)                  ; Person is human. [should match cb-np]
    (aggressive (beast) b-ab)             ; Beast is agressive.
    (attack (beast bpers) b-abp)          ; Beast attacks person.
    (cause (b-ab b-abp) b-ab->abp)        ; Beast's agressiveness causes it to attack person. [HO1]
    (harms (bpers) b-hp)                  ; Person is harmed.
    (cause (b-abp b-hp) b-abp->hp)        ; Beast attacking human harms person. [HO1]
    (helps (beast) b-hb)                  ; Beast is benefited.
    (cause (b-abp b-hb) b-abp->hb)        ; Beast attacking person benefits beast. [HO1]
    (capture (bpers beast) b-cpb)         ; Person captures beast.
    (prevent (b-cpb b-abp) b-cpb->-abp)   ; Person capturing beast prevents beast attacking person. [HO1]
    (danger-to (bpers) b-dtp)             ; Person is subject to danger.
    (cause (b-cpb b-dtp) b-cpb->dtp)      ; Person capturing beast is dangerous to person. [HO1]
   ))

;; COMMENTS are same as for beast-propns above but with a new beast.
(defvar beastly-crime-propns
  '(
    (not-criminal (cpers) cb-np)
    (aggressive (crim-pers) cb-ap)
    (victimize (crim-pers cpers) cb-vpp)
    (cause (cb-ap cb-vpp) cb-ap->vpp)
    (harms (cpers) cb-hcp)
    (cause (cb-vpp cb-hcp) cb-vpp->hcp)
    (helps (crim-pers) cb-hp)
    (cause (cb-vpp cb-hp) cb-vpp->hp)
    (capture (cpers crim-pers) cb-cpc)
    (prevent (cb-cpc cb-vpp) cb-cpc->-vpp)
    (danger-to (cpers) cb-dtp)
    (cause (cb-cpc cb-dtp) cb-cpc->dtp)
   ))

(defvar semantic-relations
  '(
    (similar 'cause 'prevent (* -1 *ident-weight*)) ; avoid mapping cause to prevent
    (semantic-iff 'cb-vpp 'v-ipa -.1)
    (semantic-iff 'cv-rpa 'b-abp -.1)
    (similar 'is-beastly 'is-infected (* -1 *ident-weight*))
   ))

(defvar crime-propns `(,@viral-crime-propns ,@beastly-crime-propns))

(defvar virus-propn-syms (mapcar #'third virus-propns))
(defvar beast-propn-syms (mapcar #'third beast-propns))
(defvar viral-crime-propn-syms (mapcar #'third viral-crime-propns))
(defvar beastly-crime-propn-syms (mapcar #'third beastly-crime-propns))
(defvar crime-propn-syms (mapcar #'third crime-propns))
