;; title: Oracle Integration Contract
;; version: 1.0.0
;; summary: Fetches real-world data for insurance claims validation
;; description: Integrates with oracles to retrieve external data for claim verification

(define-constant DATA_TYPE_WEATHER (u1))
(define-constant DATA_TYPE_EVENT (u2))
(define-constant DATA_TYPE_PRICE (u3))
(define-constant DATA_TYPE_LOCATION (u4))
(define-constant DATA_TYPE_TIMESTAMP (u5))

;; Data status
(define-constant DATA_STATUS_PENDING (u1))
(define-constant DATA_STATUS_VERIFIED (u2))
(define-constant DATA_STATUS_INVALID (u3))

(define-data-var contract-owner (optional principal) none)

;; Set contract owner (can only be called once)
(define-public (set-contract-owner (owner principal))
  (begin
    (asserts! (is-none (var-get contract-owner)) (err u6012))
    (var-set contract-owner (some owner))
    (ok true)
  )
)

(define-data-var next-request-id uint u1)

(define-map oracle-requests
  { request-id: uint }
  {
    claim-id: uint,
    data-type: uint,
    query-params: (string-ascii 200),
    status: uint,
    requested-at: uint,
    verified-at: (optional uint),
    data-value: (optional (string-ascii 500))
  }
)

(define-map claim-oracle-requests
  { claim-id: uint, request-id: uint }
  bool
)

(define-map oracle-providers
  { provider: principal }
  {
    is-active: bool,
    reputation: uint,
    total-requests: uint,
    successful-requests: uint
  }
)

(define-map verified-data
  { data-hash: (buff 32) }
  {
    data-value: (string-ascii 500),
    verified-at: uint,
    provider: principal
  }
)

;; Events
(define-public-event oracle-request-created
  (request-id uint)
  (claim-id uint)
  (data-type uint)
)

(define-public-event oracle-data-received
  (request-id uint)
  (data-value (string-ascii 500))
  (provider principal)
)

(define-public-event oracle-data-verified
  (request-id uint)
  (data-hash (buff 32))
)

;; Register oracle provider (owner only)
(define-public (register-oracle-provider (provider principal))
  (let
    (
      (existing-provider (map-get? oracle-providers { provider: provider }))
    )
    (asserts! (is-some (var-get contract-owner)) (err u6013))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u6014))) (err u6001))
    (try! (map-set oracle-providers
      { provider: provider }
      {
        is-active: true,
        reputation: (if (is-none existing-provider) u100 (get reputation (unwrap! existing-provider))),
        total-requests: (if (is-none existing-provider) u0 (get total-requests (unwrap! existing-provider))),
        successful-requests: (if (is-none existing-provider) u0 (get successful-requests (unwrap! existing-provider)))
      }
    ))
    (ok true)
  )
)

;; Create oracle data request
(define-public (request-oracle-data
    (claim-id uint)
    (data-type uint)
    (query-params (string-ascii 200))
  )
  (let
    (
      (request-id (var-get next-request-id))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u6002)))
    )
    (asserts! (or
      (is-eq data-type DATA_TYPE_WEATHER)
      (is-eq data-type DATA_TYPE_EVENT)
      (is-eq data-type DATA_TYPE_PRICE)
      (is-eq data-type DATA_TYPE_LOCATION)
      (is-eq data-type DATA_TYPE_TIMESTAMP)
    ) (err u6004))
    (try! (map-set oracle-requests
      { request-id: request-id }
      {
        claim-id: claim-id,
        data-type: data-type,
        query-params: query-params,
        status: DATA_STATUS_PENDING,
        requested-at: current-time,
        verified-at: none,
        data-value: none
      }
    ))
    (try! (map-set claim-oracle-requests
      { claim-id: claim-id, request-id: request-id }
      true
    ))
    (var-set next-request-id (+ request-id u1))
    (ok (emit-event oracle-request-created request-id claim-id data-type))
  )
)

;; Submit oracle data (oracle provider only)
(define-public (submit-oracle-data
    (request-id uint)
    (data-value (string-ascii 500))
  )
  (let
    (
      (request (unwrap! (map-get? oracle-requests { request-id: request-id }) (err u6005)))
      (provider (unwrap! (map-get? oracle-providers { provider: tx-sender }) (err u6006)))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u6002)))
      (data-hash (sha256 (unwrap! (as-max-len? (string-to-utf8 data-value) u32) (err u6011))))
    )
    (asserts! (get is-active provider) (err u6007))
    (asserts! (is-eq (get status request) DATA_STATUS_PENDING) (err u6008))
    (try! (map-set oracle-requests
      { request-id: request-id }
      {
        claim-id: (get claim-id request),
        data-type: (get data-type request),
        query-params: (get query-params request),
        status: DATA_STATUS_VERIFIED,
        requested-at: (get requested-at request),
        verified-at: (some current-time),
        data-value: (some data-value)
      }
    ))
    (try! (map-set verified-data
      { data-hash: data-hash }
      {
        data-value: data-value,
        verified-at: current-time,
        provider: tx-sender
      }
    ))
    (try! (map-set oracle-providers
      { provider: tx-sender }
      {
        is-active: (get is-active provider),
        reputation: (+ (get reputation provider) u1),
        total-requests: (+ (get total-requests provider) u1),
        successful-requests: (+ (get successful-requests provider) u1)
      }
    ))
    (ok (emit-event oracle-data-received request-id data-value tx-sender))
  )
)

;; Verify oracle data (owner only)
(define-public (verify-oracle-data
    (request-id uint)
    (is-valid bool)
  )
  (let
    (
      (request (unwrap! (map-get? oracle-requests { request-id: request-id }) (err u6005)))
    )
    (asserts! (is-some (var-get contract-owner)) (err u6013))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u6014))) (err u6001))
    (asserts! (is-eq (get status request) DATA_STATUS_VERIFIED) (err u6009))
    (try! (map-set oracle-requests
      { request-id: request-id }
      {
        claim-id: (get claim-id request),
        data-type: (get data-type request),
        query-params: (get query-params request),
        status: (if is-valid DATA_STATUS_VERIFIED DATA_STATUS_INVALID),
        requested-at: (get requested-at request),
        verified-at: (get verified-at request),
        data-value: (get data-value request)
      }
    ))
    (ok true)
  )
)

;; Get oracle request
(define-read-only (get-oracle-request (request-id uint))
  (ok (map-get? oracle-requests { request-id: request-id }))
)

;; Get verified data by hash
(define-read-only (get-verified-data (data-hash (buff 32)))
  (ok (map-get? verified-data { data-hash: data-hash }))
)

;; Get oracle provider info
(define-read-only (get-oracle-provider (provider principal))
  (ok (map-get? oracle-providers { provider: provider }))
)

;; Check if data is verified
(define-read-only (is-data-verified (request-id uint))
  (let
    (
      (request (unwrap! (map-get? oracle-requests { request-id: request-id }) (err u6005)))
    )
    (ok (is-eq (get status request) DATA_STATUS_VERIFIED))
  )
)

;; Update provider reputation (owner only)
(define-public (update-provider-reputation
    (provider principal)
    (reputation-change int)
  )
  (let
    (
      (provider-info (unwrap! (map-get? oracle-providers { provider: provider }) (err u6006)))
      (new-reputation (if (>= reputation-change (to-int u0))
        (+ (get reputation provider-info) (unwrap! (int-to-uint reputation-change) (err u6015)))
        (- (get reputation provider-info) (unwrap! (int-to-uint (* reputation-change (to-int u-1))) (err u6016)))
      ))
    )
    (asserts! (is-some (var-get contract-owner)) (err u6013))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u6014))) (err u6001))
    (asserts! (> new-reputation u0) (err u6010))
    (try! (map-set oracle-providers
      { provider: provider }
      {
        is-active: (get is-active provider-info),
        reputation: new-reputation,
        total-requests: (get total-requests provider-info),
        successful-requests: (get successful-requests provider-info)
      }
    ))
    (ok true)
  )
)

;; Deactivate oracle provider (owner only)
(define-public (deactivate-oracle-provider (provider principal))
  (let
    (
      (provider-info (unwrap! (map-get? oracle-providers { provider: provider }) (err u6006)))
    )
    (asserts! (is-some (var-get contract-owner)) (err u6013))
    (asserts! (is-eq tx-sender (unwrap! (var-get contract-owner) (err u6014))) (err u6001))
    (try! (map-set oracle-providers
      { provider: provider }
      {
        is-active: false,
        reputation: (get reputation provider-info),
        total-requests: (get total-requests provider-info),
        successful-requests: (get successful-requests provider-info)
      }
    ))
    (ok true)
  )
)
