;; title: Liquidity Pool Contract
;; version: 1.0.0
;; summary: Manages underwriter capital and liquidity in the insurance pool
;; description: Handles deposits, withdrawals, and capital management for underwriters

(define-constant MIN_DEPOSIT (u1000000))

;; Withdrawal status
(define-constant WITHDRAWAL_PENDING (u1))
(define-constant WITHDRAWAL_APPROVED (u2))
(define-constant WITHDRAWAL_REJECTED (u3))

(define-data-var contract-owner (optional principal) none)

;; Set contract owner (can only be called once)
(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-none (var-get contract-owner)) (err u3011))
    (var-set contract-owner (some owner))
    (ok true)
  )
)

(define-data-var total-liquidity uint u0)
(define-data-var total-reserved uint u0)

(define-map underwriter-balances
  { underwriter: principal }
  {
    deposited: uint,
    available: uint,
    reserved: uint,
    total-earnings: uint
  }
)

(define-map withdrawal-requests
  { request-id: uint }
  {
    underwriter: principal,
    amount: uint,
    status: uint,
    requested-at: uint
  }
)

(define-data-var next-withdrawal-id uint u1)

;; Events
(define-public-event liquidity-deposited
  (underwriter principal)
  (amount uint)
  (total-liquidity uint)
)

(define-public-event liquidity-withdrawn
  (underwriter principal)
  (amount uint)
  (request-id uint)
)

(define-public-event withdrawal-requested
  (request-id uint)
  (underwriter principal)
  (amount uint)
)

;; Deposit liquidity into the pool
(define-public (deposit-liquidity (amount uint))
  (let
    (
      (current-balance (default-to
        {
          deposited: u0,
          available: u0,
          reserved: u0,
          total-earnings: u0
        }
        (map-get? underwriter-balances { underwriter: tx-sender })
      ))
      (new-deposited (+ (get deposited current-balance) amount))
      (new-available (+ (get available current-balance) amount))
    )
    (asserts! (>= amount MIN_DEPOSIT) (err u3001))
    (try! (map-set underwriter-balances
      { underwriter: tx-sender }
      {
        deposited: new-deposited,
        available: new-available,
        reserved: (get reserved current-balance),
        total-earnings: (get total-earnings current-balance)
      }
    ))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    (ok (emit-event liquidity-deposited tx-sender amount (var-get total-liquidity)))
  )
)

;; Request withdrawal
(define-public (request-withdrawal (amount uint))
  (let
    (
      (balance (unwrap! (map-get? underwriter-balances { underwriter: tx-sender }) (err u3002)))
      (request-id (var-get next-withdrawal-id))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u3003)))
    )
    (asserts! (>= (get available balance) amount) (err u3004))
    (asserts! (> amount u0) (err u3005))
    (try! (map-set withdrawal-requests
      { request-id: request-id }
      {
        underwriter: tx-sender,
        amount: amount,
        status: WITHDRAWAL_PENDING,
        requested-at: current-time
      }
    ))
    (try! (map-set underwriter-balances
      { underwriter: tx-sender }
      {
        deposited: (get deposited balance),
        available: (- (get available balance) amount),
        reserved: (+ (get reserved balance) amount),
        total-earnings: (get total-earnings balance)
      }
    ))
    (var-set total-reserved (+ (var-get total-reserved) amount))
    (var-set next-withdrawal-id (+ request-id u1))
    (ok (emit-event withdrawal-requested request-id tx-sender amount))
  )
)

;; Approve withdrawal (owner only)
(define-public (approve-withdrawal (request-id uint))
  (let
    (
      (request (unwrap! (map-get? withdrawal-requests { request-id: request-id }) (err u3006)))
      (balance (unwrap! (map-get? underwriter-balances { underwriter: (get underwriter request) }) (err u3002)))
    )
    (asserts! (is-some (var-get contract-owner)) (err u3012))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u3013))) (err u3007))
    (asserts! (is-eq (get status request) WITHDRAWAL_PENDING) (err u3008))
    (try! (map-set withdrawal-requests
      { request-id: request-id }
      {
        underwriter: (get underwriter request),
        amount: (get amount request),
        status: WITHDRAWAL_APPROVED,
        requested-at: (get requested-at request)
      }
    ))
    (try! (map-set underwriter-balances
      { underwriter: (get underwriter request) }
      {
        deposited: (- (get deposited balance) (get amount request)),
        available: (get available balance),
        reserved: (- (get reserved balance) (get amount request)),
        total-earnings: (get total-earnings balance)
      }
    ))
    (var-set total-liquidity (- (var-get total-liquidity) (get amount request)))
    (var-set total-reserved (- (var-get total-reserved) (get amount request)))
    (ok (emit-event liquidity-withdrawn (get underwriter request) (get amount request) request-id))
  )
)

;; Reject withdrawal (owner only)
(define-public (reject-withdrawal (request-id uint))
  (let
    (
      (request (unwrap! (map-get? withdrawal-requests { request-id: request-id }) (err u3006)))
      (balance (unwrap! (map-get? underwriter-balances { underwriter: (get underwriter request) }) (err u3002)))
    )
    (asserts! (is-some (var-get contract-owner)) (err u3012))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u3013))) (err u3007))
    (asserts! (is-eq (get status request) WITHDRAWAL_PENDING) (err u3008))
    (try! (map-set withdrawal-requests
      { request-id: request-id }
      {
        underwriter: (get underwriter request),
        amount: (get amount request),
        status: WITHDRAWAL_REJECTED,
        requested-at: (get requested-at request)
      }
    ))
    (try! (map-set underwriter-balances
      { underwriter: (get underwriter request) }
      {
        deposited: (get deposited balance),
        available: (+ (get available balance) (get amount request)),
        reserved: (- (get reserved balance) (get amount request)),
        total-earnings: (get total-earnings balance)
      }
    ))
    (var-set total-reserved (- (var-get total-reserved) (get amount request)))
    (ok true)
  )
)

;; Reserve liquidity for a claim
(define-public (reserve-liquidity (amount uint))
  (let
    (
      (available-liquidity (- (var-get total-liquidity) (var-get total-reserved)))
    )
    (asserts! (>= available-liquidity amount) (err u3009))
    (var-set total-reserved (+ (var-get total-reserved) amount))
    (ok true)
  )
)

;; Release reserved liquidity
(define-public (release-reserved-liquidity (amount uint))
  (let
    (
      (current-reserved (var-get total-reserved))
    )
    (asserts! (>= current-reserved amount) (err u3010))
    (var-set total-reserved (- current-reserved amount))
    (ok true)
  )
)

;; Get underwriter balance
(define-read-only (get-underwriter-balance (underwriter principal))
  (ok (map-get? underwriter-balances { underwriter: underwriter }))
)

;; Get total liquidity
(define-read-only (get-total-liquidity)
  (ok (var-get total-liquidity))
)

;; Get available liquidity
(define-read-only (get-available-liquidity)
  (ok (- (var-get total-liquidity) (var-get total-reserved)))
)

;; Add earnings to underwriter
(define-public (add-earnings (underwriter principal) (amount uint))
  (let
    (
      (balance (unwrap! (map-get? underwriter-balances { underwriter: underwriter }) (err u3002)))
    )
    (asserts! (is-some (var-get contract-owner)) (err u3012))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u3013))) (err u3007))
    (try! (map-set underwriter-balances
      { underwriter: underwriter }
      {
        deposited: (get deposited balance),
        available: (+ (get available balance) amount),
        reserved: (get reserved balance),
        total-earnings: (+ (get total-earnings balance) amount)
      }
    ))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    (ok true)
  )
)
