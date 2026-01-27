;; title: Premium Calculator Contract
;; version: 1.0.0
;; summary: Calculates insurance premiums based on risk factors
;; description: This contract computes premium amounts using various risk assessment parameters

(define-constant BASE_RISK_MULTIPLIER (u10000))
(define-constant LOW_RISK_MULTIPLIER (u8000))
(define-constant MEDIUM_RISK_MULTIPLIER (u12000))
(define-constant HIGH_RISK_MULTIPLIER (u18000))
(define-constant VERY_HIGH_RISK_MULTIPLIER (u25000))

;; Base premium rate (in basis points per coverage unit)
(define-constant BASE_PREMIUM_RATE (u100))

;; Risk category constants
(define-constant RISK_CATEGORY_LOW (string-ascii 20 "low"))
(define-constant RISK_CATEGORY_MEDIUM (string-ascii 20 "medium"))
(define-constant RISK_CATEGORY_HIGH (string-ascii 20 "high"))
(define-constant RISK_CATEGORY_VERY_HIGH (string-ascii 20 "very_high"))

(define-data-var contract-owner (optional principal) none)

;; Set contract owner (can only be called once)
(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-none (var-get contract-owner)) (err u2007))
    (var-set contract-owner (some owner))
    (ok true)
  )
)

(define-map risk-factors
  { risk-category: (string-ascii 20) }
  { multiplier: uint, base-rate: uint }
)

(define-map coverage-multipliers
  { coverage-tier: uint }
  uint
)

;; Initialize risk factors
(define-public (initialize-risk-factors)
  (begin
    (asserts! (is-some (var-get contract-owner)) (err u2008))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u2009))) (err u2001))
    (try! (map-set risk-factors
      { risk-category: RISK_CATEGORY_LOW }
      { multiplier: LOW_RISK_MULTIPLIER, base-rate: BASE_PREMIUM_RATE }
    ))
    (try! (map-set risk-factors
      { risk-category: RISK_CATEGORY_MEDIUM }
      { multiplier: MEDIUM_RISK_MULTIPLIER, base-rate: BASE_PREMIUM_RATE }
    ))
    (try! (map-set risk-factors
      { risk-category: RISK_CATEGORY_HIGH }
      { multiplier: HIGH_RISK_MULTIPLIER, base-rate: BASE_PREMIUM_RATE }
    ))
    (try! (map-set risk-factors
      { risk-category: RISK_CATEGORY_VERY_HIGH }
      { multiplier: VERY_HIGH_RISK_MULTIPLIER, base-rate: BASE_PREMIUM_RATE }
    ))
    (ok true)
  )
)

;; Calculate premium based on coverage amount and risk category
(define-public (calculate-premium
    (coverage-amount uint)
    (risk-category (string-ascii 20))
    (duration-days uint)
  )
  (let
    (
      (risk-factor (unwrap! (map-get? risk-factors { risk-category: risk-category }) (err u2002)))
      (base-premium (* coverage-amount (/ (get base-rate risk-factor) u10000)))
      (risk-adjusted-premium (* base-premium (/ (get multiplier risk-factor) u10000)))
      (duration-multiplier (+ u10000 (/ (* duration-days u100) u365)))
      (final-premium (* risk-adjusted-premium (/ duration-multiplier u10000)))
    )
    (ok final-premium)
  )
)

;; Calculate premium with additional factors
(define-public (calculate-premium-advanced
    (coverage-amount uint)
    (risk-category (string-ascii 20))
    (duration-days uint)
    (age-factor uint)
    (history-factor uint)
  )
  (let
    (
      (base-premium-result (unwrap! (calculate-premium coverage-amount risk-category duration-days) (err u2003)))
      (age-adjusted (* base-premium-result (/ age-factor u10000)))
      (history-adjusted (* age-adjusted (/ history-factor u10000)))
    )
    (ok history-adjusted)
  )
)

;; Get risk factor for a category
(define-read-only (get-risk-factor (risk-category (string-ascii 20)))
  (ok (map-get? risk-factors { risk-category: risk-category }))
)

;; Update risk multiplier for a category (owner only)
(define-public (update-risk-multiplier
    (risk-category (string-ascii 20))
    (new-multiplier uint)
  )
  (let
    (
      (risk-factor (unwrap! (map-get? risk-factors { risk-category: risk-category }) (err u2002)))
    )
    (asserts! (is-some (var-get contract-owner)) (err u2010))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u2011))) (err u2004))
    (asserts! (>= new-multiplier u5000) (err u2005))
    (asserts! (<= new-multiplier u50000) (err u2006))
    (try! (map-set risk-factors
      { risk-category: risk-category }
      { multiplier: new-multiplier, base-rate: (get base-rate risk-factor) }
    ))
    (ok true)
  )
)

;; Calculate coverage tier multiplier
(define-read-only (get-coverage-tier-multiplier (coverage-amount uint))
  (cond
    ((< coverage-amount u10000) (ok u10000))
    ((< coverage-amount u50000) (ok u11000))
    ((< coverage-amount u100000) (ok u12000))
    ((< coverage-amount u500000) (ok u15000))
    (else (ok u20000))
  )
)

;; Calculate final premium with coverage tier
(define-public (calculate-premium-with-tier
    (coverage-amount uint)
    (risk-category (string-ascii 20))
    (duration-days uint)
  )
  (let
    (
      (base-premium (unwrap! (calculate-premium coverage-amount risk-category duration-days) (err u2003)))
      (tier-multiplier (unwrap! (get-coverage-tier-multiplier coverage-amount) (err u2007)))
      (final-premium (* base-premium (/ tier-multiplier u10000)))
    )
    (ok final-premium)
  )
)
