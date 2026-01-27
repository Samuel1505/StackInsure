;; title: Voting Contract
;; version: 1.0.0
;; summary: Multi-party claim voting mechanism
;; description: Enables multiple parties to vote on claim validity and outcomes

(define-constant VOTE_APPROVE (u1))
(define-constant VOTE_REJECT (u2))
(define-constant VOTE_ABSTAIN (u3))

;; Voting status
(define-constant VOTING_OPEN (u1))
(define-constant VOTING_CLOSED (u2))
(define-constant VOTING_RESOLVED (u3))

;; Minimum voting period (in blocks)
(define-constant MIN_VOTING_PERIOD (u100))
(define-constant DEFAULT_VOTING_PERIOD (u144))

;; Minimum votes required
(define-constant MIN_VOTES_REQUIRED (u3))

(define-data-var contract-owner principal tx-sender)

(define-data-var next-voting-session-id uint u1)

(define-map voting-sessions
  { session-id: uint }
  {
    claim-id: uint,
    status: uint,
    start-block: uint,
    end-block: uint,
    votes-approve: uint,
    votes-reject: uint,
    votes-abstain: uint,
    quorum: uint
  }
)

(define-map votes
  { session-id: uint, voter: principal }
  {
    vote: uint,
    voted-at: uint,
    weight: uint
  }
)

(define-map voter-weights
  { voter: principal }
  uint
)

(define-map claim-voting-sessions
  { claim-id: uint }
  uint
)

;; Events
(define-public-event voting-session-created
  (session-id uint)
  (claim-id uint)
  (end-block uint)
)

(define-public-event vote-cast
  (session-id uint)
  (voter principal)
  (vote uint)
  (weight uint)
)

(define-public-event voting-closed
  (session-id uint)
  (result uint)
  (approve-votes uint)
  (reject-votes uint)
)

;; Set voter weight (owner only)
(define-public (set-voter-weight (voter principal) (weight uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u5001))
    (asserts! (> weight u0) (err u5002))
    (try! (map-set voter-weights { voter: voter } weight))
    (ok true)
  )
)

;; Create a voting session for a claim
(define-public (create-voting-session
    (claim-id uint)
    (voting-period uint)
    (quorum uint)
  )
  (let
    (
      (session-id (var-get next-voting-session-id))
      (current-block (unwrap! (get-block-height?) (err u5003)))
      (end-block (+ current-block (if (>= voting-period MIN_VOTING_PERIOD) voting-period DEFAULT_VOTING_PERIOD)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u5001))
    (asserts! (> quorum u0) (err u5004))
    (try! (map-set voting-sessions
      { session-id: session-id }
      {
        claim-id: claim-id,
        status: VOTING_OPEN,
        start-block: current-block,
        end-block: end-block,
        votes-approve: u0,
        votes-reject: u0,
        votes-abstain: u0,
        quorum: quorum
      }
    ))
    (try! (map-set claim-voting-sessions { claim-id: claim-id } session-id))
    (var-set next-voting-session-id (+ session-id u1))
    (ok (emit-event voting-session-created session-id claim-id end-block))
  )
)

;; Cast a vote
(define-public (cast-vote
    (session-id uint)
    (vote-option uint)
  )
  (let
    (
      (session (unwrap! (map-get? voting-sessions { session-id: session-id }) (err u5005)))
      (current-block (unwrap! (get-block-height?) (err u5003)))
      (voter-weight (default-to u1 (map-get? voter-weights { voter: tx-sender })))
      (existing-vote (map-get? votes { session-id: session-id, voter: tx-sender }))
    )
    (asserts! (is-eq (get status session) VOTING_OPEN) (err u5006))
    (asserts! (<= current-block (get end-block session)) (err u5007))
    (asserts! (is-none existing-vote) (err u5008))
    (asserts! (or
      (is-eq vote-option VOTE_APPROVE)
      (is-eq vote-option VOTE_REJECT)
      (is-eq vote-option VOTE_ABSTAIN)
    ) (err u5009))
    (try! (map-set votes
      { session-id: session-id, voter: tx-sender }
      {
        vote: vote-option,
        voted-at: current-block,
        weight: voter-weight
      }
    ))
    (let
      (
        (new-approve (if (is-eq vote-option VOTE_APPROVE)
          (+ (get votes-approve session) voter-weight)
          (get votes-approve session)
        ))
        (new-reject (if (is-eq vote-option VOTE_REJECT)
          (+ (get votes-reject session) voter-weight)
          (get votes-reject session)
        ))
        (new-abstain (if (is-eq vote-option VOTE_ABSTAIN)
          (+ (get votes-abstain session) voter-weight)
          (get votes-abstain session)
        ))
      )
      (try! (map-set voting-sessions
        { session-id: session-id }
        {
          claim-id: (get claim-id session),
          status: (get status session),
          start-block: (get start-block session),
          end-block: (get end-block session),
          votes-approve: new-approve,
          votes-reject: new-reject,
          votes-abstain: new-abstain,
          quorum: (get quorum session)
        }
      ))
      (ok (emit-event vote-cast session-id tx-sender vote-option voter-weight))
    )
  )
)

;; Close voting session and determine result
(define-public (close-voting-session (session-id uint))
  (let
    (
      (session (unwrap! (map-get? voting-sessions { session-id: session-id }) (err u5005)))
      (current-block (unwrap! (get-block-height?) (err u5003)))
      (total-votes (+ (get votes-approve session) (+ (get votes-reject session) (get votes-abstain session))))
      (result (if (>= total-votes (get quorum session))
        (if (> (get votes-approve session) (get votes-reject session))
          VOTE_APPROVE
          (if (> (get votes-reject session) (get votes-approve session))
            VOTE_REJECT
            VOTE_ABSTAIN
          )
        )
        VOTE_ABSTAIN
      ))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u5001))
    (asserts! (is-eq (get status session) VOTING_OPEN) (err u5006))
    (asserts! (or
      (> current-block (get end-block session))
      (>= total-votes (get quorum session))
    ) (err u5010))
    (try! (map-set voting-sessions
      { session-id: session-id }
      {
        claim-id: (get claim-id session),
        status: VOTING_CLOSED,
        start-block: (get start-block session),
        end-block: (get end-block session),
        votes-approve: (get votes-approve session),
        votes-reject: (get votes-reject session),
        votes-abstain: (get votes-abstain session),
        quorum: (get quorum session)
      }
    ))
    (ok (emit-event voting-closed session-id result (get votes-approve session) (get votes-reject session)))
  )
)

;; Get voting session details
(define-read-only (get-voting-session (session-id uint))
  (ok (map-get? voting-sessions { session-id: session-id }))
)

;; Get vote for a voter in a session
(define-read-only (get-vote (session-id uint) (voter principal))
  (ok (map-get? votes { session-id: session-id, voter: voter }))
)

;; Get voting session for a claim
(define-read-only (get-claim-voting-session (claim-id uint))
  (ok (map-get? claim-voting-sessions { claim-id: claim-id }))
)

;; Check if voting is still open
(define-read-only (is-voting-open (session-id uint))
  (let
    (
      (session (unwrap! (map-get? voting-sessions { session-id: session-id }) (err u5005)))
      (current-block (unwrap! (get-block-height?) (err u5003)))
    )
    (ok (and
      (is-eq (get status session) VOTING_OPEN)
      (<= current-block (get end-block session))
    ))
  )
)

;; Get voting result
(define-read-only (get-voting-result (session-id uint))
  (let
    (
      (session (unwrap! (map-get? voting-sessions { session-id: session-id }) (err u5005)))
      (total-votes (+ (get votes-approve session) (+ (get votes-reject session) (get votes-abstain session))))
    )
    (ok (if (>= total-votes (get quorum session))
      (if (> (get votes-approve session) (get votes-reject session))
        (some VOTE_APPROVE)
        (if (> (get votes-reject session) (get votes-approve session))
          (some VOTE_REJECT)
          (some VOTE_ABSTAIN)
        )
      )
      none
    ))
  )
)
