;; title: Claims Processing Contract
;; version: 1.0.0
;; summary: Handles claim submissions and validation
;; description: Manages the lifecycle of insurance claims from submission to resolution

(define-constant CLAIM_STATUS_SUBMITTED (u1))
(define-constant CLAIM_STATUS_UNDER_REVIEW (u2))
(define-constant CLAIM_STATUS_APPROVED (u3))
(define-constant CLAIM_STATUS_REJECTED (u4))
(define-constant CLAIM_STATUS_PAID (u5))

;; Minimum claim amount
(define-constant MIN_CLAIM_AMOUNT (u1000))

(define-data-var contract-owner principal tx-sender)

(define-data-var next-claim-id uint u1)

(define-map claims
  { claim-id: uint }
  {
    policy-id: uint,
    claimant: principal,
    claim-amount: uint,
    description: (string-ascii 200),
    status: uint,
    submitted-at: uint,
    reviewed-at: (optional uint),
    resolved-at: (optional uint),
    evidence-hash: (buff 32)
  }
)

(define-map policy-claims
  { policy-id: uint, claim-id: uint }
  bool
)

(define-map claimant-claims
  { claimant: principal, claim-id: uint }
  bool
)

;; Events
(define-public-event claim-submitted
  (claim-id uint)
  (policy-id uint)
  (claimant principal)
  (claim-amount uint)
)

(define-public-event claim-status-updated
  (claim-id uint)
  (old-status uint)
  (new-status uint)
)

(define-public-event claim-approved
  (claim-id uint)
  (claim-amount uint)
)

(define-public-event claim-rejected
  (claim-id uint)
  (reason (string-ascii 100))
)

;; Submit a new claim
(define-public (submit-claim
    (policy-id uint)
    (claim-amount uint)
    (description (string-ascii 200))
    (evidence-hash (buff 32))
  )
  (let
    (
      (claim-id (var-get next-claim-id))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u4001)))
    )
    (asserts! (>= claim-amount MIN_CLAIM_AMOUNT) (err u4002))
    (try! (map-set claims
      { claim-id: claim-id }
      {
        policy-id: policy-id,
        claimant: tx-sender,
        claim-amount: claim-amount,
        description: description,
        status: CLAIM_STATUS_SUBMITTED,
        submitted-at: current-time,
        reviewed-at: none,
        resolved-at: none,
        evidence-hash: evidence-hash
      }
    ))
    (try! (map-set policy-claims
      { policy-id: policy-id, claim-id: claim-id }
      true
    ))
    (try! (map-set claimant-claims
      { claimant: tx-sender, claim-id: claim-id }
      true
    ))
    (var-set next-claim-id (+ claim-id u1))
    (ok (emit-event claim-submitted claim-id policy-id tx-sender claim-amount))
  )
)

;; Get claim information
(define-read-only (get-claim (claim-id uint))
  (ok (map-get? claims { claim-id: claim-id }))
)

;; Update claim status (owner or authorized reviewer)
(define-public (update-claim-status
    (claim-id uint)
    (new-status uint)
  )
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) (err u4004)))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u4001)))
      (reviewed-time (if (is-none (get reviewed-at claim)) (some current-time) (get reviewed-at claim)))
      (resolved-time (if (or (is-eq new-status CLAIM_STATUS_APPROVED) (is-eq new-status CLAIM_STATUS_REJECTED))
        (some current-time)
        (get resolved-at claim)
      ))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u4005))
    (asserts! (is-eq (get status claim) CLAIM_STATUS_SUBMITTED) (err u4006))
    (try! (map-set claims
      { claim-id: claim-id }
      {
        policy-id: (get policy-id claim),
        claimant: (get claimant claim),
        claim-amount: (get claim-amount claim),
        description: (get description claim),
        status: new-status,
        submitted-at: (get submitted-at claim),
        reviewed-at: reviewed-time,
        resolved-at: resolved-time,
        evidence-hash: (get evidence-hash claim)
      }
    ))
    (ok (emit-event claim-status-updated claim-id (get status claim) new-status))
  )
)

;; Approve a claim
(define-public (approve-claim (claim-id uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) (err u4004)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u4005))
    (asserts! (is-eq (get status claim) CLAIM_STATUS_UNDER_REVIEW) (err u4007))
    (try! (update-claim-status claim-id CLAIM_STATUS_APPROVED))
    (ok (emit-event claim-approved claim-id (get claim-amount claim)))
  )
)

;; Reject a claim
(define-public (reject-claim
    (claim-id uint)
    (reason (string-ascii 100))
  )
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) (err u4004)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u4005))
    (asserts! (or
      (is-eq (get status claim) CLAIM_STATUS_SUBMITTED)
      (is-eq (get status claim) CLAIM_STATUS_UNDER_REVIEW)
    ) (err u4008))
    (try! (update-claim-status claim-id CLAIM_STATUS_REJECTED))
    (ok (emit-event claim-rejected claim-id reason))
  )
)

;; Mark claim as under review
(define-public (mark-claim-under-review (claim-id uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) (err u4004)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u4005))
    (asserts! (is-eq (get status claim) CLAIM_STATUS_SUBMITTED) (err u4009))
    (try! (update-claim-status claim-id CLAIM_STATUS_UNDER_REVIEW))
    (ok true)
  )
)

;; Mark claim as paid
(define-public (mark-claim-paid (claim-id uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) (err u4004)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u4005))
    (asserts! (is-eq (get status claim) CLAIM_STATUS_APPROVED) (err u4010))
    (try! (update-claim-status claim-id CLAIM_STATUS_PAID))
    (ok true)
  )
)

;; Check if claim is valid for a policy
(define-read-only (is-claim-valid (claim-id uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) (err u4004)))
    )
    (ok (and
      (>= (get claim-amount claim) MIN_CLAIM_AMOUNT)
      (or
        (is-eq (get status claim) CLAIM_STATUS_SUBMITTED)
        (is-eq (get status claim) CLAIM_STATUS_UNDER_REVIEW)
        (is-eq (get status claim) CLAIM_STATUS_APPROVED)
      )
    ))
  )
)

;; Get total claims count
(define-read-only (get-total-claims)
  (ok (var-get next-claim-id))
)

;; Get claims by policy
(define-read-only (has-policy-claim (policy-id uint) (claim-id uint))
  (ok (map-get? policy-claims { policy-id: policy-id, claim-id: claim-id }))
)
