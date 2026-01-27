;; title: Staking Contract
;; version: 1.0.0
;; summary: Manages underwriter stakes and rewards
;; description: Handles staking, unstaking, and reward distribution for underwriters

(define-constant MIN_STAKE (u1000000))

;; Staking status
(define-constant STAKE_ACTIVE (u1))
(define-constant STAKE_UNSTAKING (u2))
(define-constant STAKE_UNSTAKED (u3))

;; Unstaking period (in blocks)
(define-constant UNSTAKING_PERIOD (u144))

;; Reward calculation constants
(define-constant REWARD_RATE_BASE (u100))
(define-constant REWARD_DECIMALS (u10000))

(define-data-var contract-owner principal tx-sender)

(define-data-var total-staked uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var reward-rate uint REWARD_RATE_BASE)

(define-map stakes
  { staker: principal }
  {
    amount: uint,
    staked-at: uint,
    status: uint,
    unstaking-requested-at: (optional uint),
    total-rewards-earned: uint,
    last-reward-claim: uint
  }
)

(define-map unstaking-requests
  { staker: principal }
  {
    amount: uint,
    requested-at: uint,
    unlock-block: uint
  }
)

(define-map reward-pool
  { pool-id: uint }
  {
    total-amount: uint,
    distributed: uint,
    created-at: uint
  }
)

(define-data-var next-pool-id uint u1)

;; Events
(define-public-event stake-deposited
  (staker principal)
  (amount uint)
  (total-staked uint)
)

(define-public-event unstaking-initiated
  (staker principal)
  (amount uint)
  (unlock-block uint)
)

(define-public-event stake-withdrawn
  (staker principal)
  (amount uint)
)

(define-public-event rewards-claimed
  (staker principal)
  (amount uint)
)

(define-public-event reward-pool-created
  (pool-id uint)
  (total-amount uint)
)

;; Deposit stake
(define-public (stake (amount uint))
  (let
    (
      (current-stake (map-get? stakes { staker: tx-sender }))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u7001)))
      (current-block (unwrap! (get-block-height?) (err u7002)))
      (existing-amount (if (is-none current-stake) u0 (get amount (unwrap! current-stake))))
      (existing-rewards (if (is-none current-stake) u0 (get total-rewards-earned (unwrap! current-stake))))
      (last-claim (if (is-none current-stake) current-time (get last-reward-claim (unwrap! current-stake))))
      (new-amount (+ existing-amount amount))
    )
    (asserts! (>= amount MIN_STAKE) (err u7003))
    (try! (map-set stakes
      { staker: tx-sender }
      {
        amount: new-amount,
        staked-at: (if (is-none current-stake) current-time (get staked-at (unwrap! current-stake))),
        status: STAKE_ACTIVE,
        unstaking-requested-at: none,
        total-rewards-earned: existing-rewards,
        last-reward-claim: last-claim
      }
    ))
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok (emit-event stake-deposited tx-sender amount (var-get total-staked)))
  )
)

;; Initiate unstaking
(define-public (initiate-unstaking (amount uint))
  (let
    (
      (stake-info (unwrap! (map-get? stakes { staker: tx-sender }) (err u7005)))
      (current-block (unwrap! (get-block-height?) (err u7002)))
      (current-time (unwrap! (get-block-info? time current-block) (err u7001)))
      (unlock-block (+ current-block UNSTAKING_PERIOD))
    )
    (asserts! (is-eq (get status stake-info) STAKE_ACTIVE) (err u7006))
    (asserts! (>= (get amount stake-info) amount) (err u7007))
    (asserts! (>= amount MIN_STAKE) (err u7008))
    (try! (map-set unstaking-requests
      { staker: tx-sender }
      {
        amount: amount,
        requested-at: current-block,
        unlock-block: unlock-block
      }
    ))
    (try! (map-set stakes
      { staker: tx-sender }
      {
        amount: (get amount stake-info),
        staked-at: (get staked-at stake-info),
        status: STAKE_UNSTAKING,
        unstaking-requested-at: (some current-block),
        total-rewards-earned: (get total-rewards-earned stake-info),
        last-reward-claim: (get last-reward-claim stake-info)
      }
    ))
    (ok (emit-event unstaking-initiated tx-sender amount unlock-block))
  )
)

;; Complete unstaking and withdraw
(define-public (withdraw-stake)
  (let
    (
      (stake-info (unwrap! (map-get? stakes { staker: tx-sender }) (err u7005)))
      (unstaking-request (unwrap! (map-get? unstaking-requests { staker: tx-sender }) (err u7009)))
      (current-block (unwrap! (get-block-height?) (err u7002)))
      (remaining-amount (- (get amount stake-info) (get amount unstaking-request)))
    )
    (asserts! (is-eq (get status stake-info) STAKE_UNSTAKING) (err u7010))
    (asserts! (>= current-block (get unlock-block unstaking-request)) (err u7011))
    (try! (map-set stakes
      { staker: tx-sender }
      {
        amount: remaining-amount,
        staked-at: (if (is-eq remaining-amount u0) u0 (get staked-at stake-info)),
        status: (if (is-eq remaining-amount u0) STAKE_UNSTAKED STAKE_ACTIVE),
        unstaking-requested-at: none,
        total-rewards-earned: (get total-rewards-earned stake-info),
        last-reward-claim: (get last-reward-claim stake-info)
      }
    ))
    (try! (map-delete unstaking-requests { staker: tx-sender }))
    (var-set total-staked (- (var-get total-staked) (get amount unstaking-request)))
    (ok (emit-event stake-withdrawn tx-sender (get amount unstaking-request)))
  )
)

;; Calculate pending rewards for a staker
(define-read-only (calculate-pending-rewards (staker principal))
  (let
    (
      (stake-info (unwrap! (map-get? stakes { staker: staker }) (err u7005)))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u7001)))
      (time-diff (- current-time (get last-reward-claim stake-info)))
      (base-reward (* (get amount stake-info) (/ reward-rate REWARD_DECIMALS)))
      (time-adjusted-reward (/ (* base-reward time-diff) u86400))
    )
    (ok (if (is-eq (get status stake-info) STAKE_ACTIVE)
      time-adjusted-reward
      u0
    ))
  )
)

;; Claim rewards
(define-public (claim-rewards)
  (let
    (
      (stake-info (unwrap! (map-get? stakes { staker: tx-sender }) (err u7005)))
      (pending-rewards (unwrap! (calculate-pending-rewards tx-sender) (err u7012)))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u7001)))
    )
    (asserts! (is-eq (get status stake-info) STAKE_ACTIVE) (err u7013))
    (asserts! (> pending-rewards u0) (err u7014))
    (try! (map-set stakes
      { staker: tx-sender }
      {
        amount: (get amount stake-info),
        staked-at: (get staked-at stake-info),
        status: (get status stake-info),
        unstaking-requested-at: (get unstaking-requested-at stake-info),
        total-rewards-earned: (+ (get total-rewards-earned stake-info) pending-rewards),
        last-reward-claim: current-time
      }
    ))
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) pending-rewards))
    (ok (emit-event rewards-claimed tx-sender pending-rewards))
  )
)

;; Get staker information
(define-read-only (get-stake-info (staker principal))
  (ok (map-get? stakes { staker: staker }))
)

;; Get total staked
(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)

;; Create reward pool (owner only)
(define-public (create-reward-pool (total-amount uint))
  (let
    (
      (pool-id (var-get next-pool-id))
      (current-time (unwrap! (get-block-info? time (unwrap! (get-block-height?))) (err u7001)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u7015))
    (asserts! (> total-amount u0) (err u7016))
    (try! (map-set reward-pool
      { pool-id: pool-id }
      {
        total-amount: total-amount,
        distributed: u0,
        created-at: current-time
      }
    ))
    (var-set next-pool-id (+ pool-id u1))
    (ok (emit-event reward-pool-created pool-id total-amount))
  )
)

;; Update reward rate (owner only)
(define-public (update-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u7015))
    (asserts! (>= new-rate u0) (err u7017))
    (asserts! (<= new-rate u1000) (err u7018))
    (var-set reward-rate new-rate)
    (ok true)
  )
)

;; Get reward rate
(define-read-only (get-reward-rate)
  (ok (var-get reward-rate))
)

;; Get unstaking request
(define-read-only (get-unstaking-request (staker principal))
  (ok (map-get? unstaking-requests { staker: staker }))
)

;; Check if unstaking is ready
(define-read-only (is-unstaking-ready (staker principal))
  (let
    (
      (unstaking-request (unwrap! (map-get? unstaking-requests { staker: staker }) (err u7009)))
      (current-block (unwrap! (get-block-height?) (err u7002)))
    )
    (ok (>= current-block (get unlock-block unstaking-request)))
  )
)
