;; title: Policy Registry Contract
;; version: 1.0.0
;; summary: Manages all insurance policies in the StackInsure system
;; description: This contract handles policy creation, updates, retrieval, and lifecycle management

(define-constant STATUS_ACTIVE (u1))
(define-constant STATUS_EXPIRED (u2))
(define-constant STATUS_CANCELLED (u3))
(define-constant STATUS_CLAIMED (u4))

(define-data-var contract-owner principal tx-sender)

;; Policy data structure
(define-data-var next-policy-id uint u1)

(define-map policy-map
  { policy-id: uint }
  {
    policy-holder: principal,
    coverage-amount: uint,
    premium-amount: uint,
    start-date: uint,
    end-date: uint,
    status: uint,
    risk-category: (string-ascii 20),
    created-at: uint
  }
)

(define-map policy-holder-policies
  { holder: principal, policy-id: uint }
  bool
)

;; Events
(define-public-event policy-created
  (policy-id uint)
  (policy-holder principal)
  (coverage-amount uint)
)

(define-public-event policy-updated
  (policy-id uint)
  (status uint)
)

;; Create a new insurance policy
(define-public (create-policy
    (coverage-amount uint)
    (premium-amount uint)
    (start-date uint)
    (end-date uint)
    (risk-category (string-ascii 20))
  )
  (let
    (
      (policy-id (var-get next-policy-id))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u1001)))
    )
    (asserts! (> end-date start-date) (err u1003))
    (asserts! (> coverage-amount u0) (err u1004))
    (asserts! (> premium-amount u0) (err u1005))
    (try! (map-set policy-map
      {
        policy-id: policy-id
      }
      {
        policy-holder: tx-sender,
        coverage-amount: coverage-amount,
        premium-amount: premium-amount,
        start-date: start-date,
        end-date: end-date,
        status: STATUS_ACTIVE,
        risk-category: risk-category,
        created-at: current-time
      }
    ))
    (try! (map-set policy-holder-policies
      {
        holder: tx-sender,
        policy-id: policy-id
      }
      true
    ))
    (var-set next-policy-id (+ policy-id u1))
    (ok (emit-event policy-created policy-id tx-sender coverage-amount))
  )
)

;; Get policy information
(define-read-only (get-policy (policy-id uint))
  (ok (map-get? policy-map { policy-id: policy-id }))
)

;; Update policy status
(define-public (update-policy-status
    (policy-id uint)
    (new-status uint)
  )
  (let
    (
      (policy (unwrap! (map-get? policy-map { policy-id: policy-id }) (err u1006)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1007))
    (try! (map-set policy-map
      {
        policy-id: policy-id
      }
      {
        policy-holder: (get policy-holder policy),
        coverage-amount: (get coverage-amount policy),
        premium-amount: (get premium-amount policy),
        start-date: (get start-date policy),
        end-date: (get end-date policy),
        status: new-status,
        risk-category: (get risk-category policy),
        created-at: (get created-at policy)
      }
    ))
    (ok (emit-event policy-updated policy-id new-status))
  )
)

;; Check if policy is active
(define-read-only (is-policy-active (policy-id uint))
  (let
    (
      (policy (unwrap! (map-get? policy-map { policy-id: policy-id }) (err u1006)))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u1001)))
    )
    (ok (and
      (is-eq (get status policy) STATUS_ACTIVE)
      (>= current-time (get start-date policy))
      (<= current-time (get end-date policy))
    ))
  )
)

;; Get all policies for a holder
(define-read-only (get-policy-count)
  (ok (var-get next-policy-id))
)

;; Cancel a policy (only by policy holder)
(define-public (cancel-policy (policy-id uint))
  (let
    (
      (policy (unwrap! (map-get? policy-map { policy-id: policy-id }) (err u1006)))
    )
    (asserts! (is-eq tx-sender (get policy-holder policy)) (err u1008))
    (asserts! (is-eq (get status policy) STATUS_ACTIVE) (err u1009))
    (try! (map-set policy-map
      {
        policy-id: policy-id
      }
      {
        policy-holder: (get policy-holder policy),
        coverage-amount: (get coverage-amount policy),
        premium-amount: (get premium-amount policy),
        start-date: (get start-date policy),
        end-date: (get end-date policy),
        status: STATUS_CANCELLED,
        risk-category: (get risk-category policy),
        created-at: (get created-at policy)
      }
    ))
    (ok (emit-event policy-updated policy-id STATUS_CANCELLED))
  )
)
