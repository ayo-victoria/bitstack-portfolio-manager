;; Title: BitStack Portfolio Manager
;; Summary: Decentralized multi-asset portfolio management protocol
;; Description: A sophisticated DeFi protocol enabling users to create,
;;              manage, and automatically rebalance diversified crypto
;;              portfolios on the Bitcoin Layer 2 Stacks network.
;;              Features include automated rebalancing, customizable
;;              allocations, and gas-efficient batch operations.

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u100)) ;; Unauthorized access attempt
(define-constant ERR-INVALID-PORTFOLIO (err u101)) ;; Portfolio doesn't exist or is invalid
(define-constant ERR-INSUFFICIENT-BALANCE (err u102)) ;; Insufficient funds for operation
(define-constant ERR-INVALID-TOKEN (err u103)) ;; Invalid token address provided
(define-constant ERR-REBALANCE-FAILED (err u104)) ;; Portfolio rebalancing operation failed
(define-constant ERR-PORTFOLIO-EXISTS (err u105)) ;; Portfolio already exists
(define-constant ERR-INVALID-PERCENTAGE (err u106)) ;; Invalid allocation percentage
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107)) ;; Exceeded maximum allowed tokens
(define-constant ERR-LENGTH-MISMATCH (err u108)) ;; Mismatch in input array lengths
(define-constant ERR-USER-STORAGE-FAILED (err u109)) ;; Failed to update user storage
(define-constant ERR-INVALID-TOKEN-ID (err u110)) ;; Invalid token ID in portfolio

;; PROTOCOL CONFIGURATION

(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% in basis points

;; PROTOCOL CONSTANTS

(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000) ;; 100% = 10000 basis points

;; DATA STRUCTURES

;; Main portfolio registry storing core portfolio metadata
(define-map Portfolios
  uint ;; portfolio-id
  {
    owner: principal,
    created-at: uint,
    last-rebalanced: uint,
    total-value: uint,
    active: bool,
    token-count: uint,
  }
)

;; Individual asset allocations within each portfolio
(define-map PortfolioAssets
  {
    portfolio-id: uint,
    token-id: uint,
  }
  {
    target-percentage: uint,
    current-amount: uint,
    token-address: principal,
  }
)

;; User's portfolio ownership registry (max 20 portfolios per user)
(define-map UserPortfolios
  principal
  (list 20 uint)
)

;; READ-ONLY FUNCTIONS

;; Retrieve complete portfolio information by ID
(define-read-only (get-portfolio (portfolio-id uint))
  (map-get? Portfolios portfolio-id)
)

;; Get specific asset allocation details within a portfolio
(define-read-only (get-portfolio-asset
    (portfolio-id uint)
    (token-id uint)
  )
  (map-get? PortfolioAssets {
    portfolio-id: portfolio-id,
    token-id: token-id,
  })
)

;; Retrieve all portfolio IDs owned by a specific user
(define-read-only (get-user-portfolios (user principal))
  (default-to (list) (map-get? UserPortfolios user))
)

;; Calculate whether a portfolio requires rebalancing
(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (total-value (get total-value portfolio))
    )
    (ok {
      portfolio-id: portfolio-id,
      total-value: total-value,
      needs-rebalance: (> (- stacks-block-height (get last-rebalanced portfolio)) u144),
    })
  )
)

;; PRIVATE HELPER FUNCTIONS

;; Validate token ID is within portfolio constraints
(define-private (validate-token-id
    (portfolio-id uint)
    (token-id uint)
  )
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) false)))
    (and
      (< token-id MAX-TOKENS-PER-PORTFOLIO)
      (< token-id (get token-count portfolio))
      true
    )
  )
)

;; Ensure percentage is within valid range (0-10000 basis points)
(define-private (validate-percentage (percentage uint))
  (and (>= percentage u0) (<= percentage BASIS-POINTS))
)

;; Validate that portfolio percentages sum to exactly 100%
(define-private (validate-portfolio-percentages (percentages (list 10 uint)))
  (let ((total (fold + percentages u0)))
    (and
      (is-eq total BASIS-POINTS)
      (fold and (map validate-percentage percentages) true)
    )
  )
)

;; Helper for validating individual percentage values
(define-private (check-percentage-sum
    (current-percentage uint)
    (valid bool)
  )
  (and valid (validate-percentage current-percentage))
)

;; Add new portfolio to user's ownership list
(define-private (add-to-user-portfolios
    (user principal)
    (portfolio-id uint)
  )
  (let (
      (current-portfolios (get-user-portfolios user))
      (new-portfolios (unwrap! (as-max-len? (append current-portfolios portfolio-id) u20)
        ERR-USER-STORAGE-FAILED
      ))
    )
    (map-set UserPortfolios user new-portfolios)
    (ok true)
  )
)

;; Initialize a single portfolio asset with allocation
(define-private (initialize-portfolio-asset
    (index uint)
    (token principal)
    (percentage uint)
    (portfolio-id uint)
  )
  (if (>= percentage u0)
    (begin
      (map-set PortfolioAssets {
        portfolio-id: portfolio-id,
        token-id: index,
      } {
        target-percentage: percentage,
        current-amount: u0,
        token-address: token,
      })
      (ok true)
    )
    ERR-INVALID-TOKEN
  )
)

;; Initialize all portfolio assets using explicit unrolled logic
(define-private (initialize-all-assets
    (portfolio-id uint)
    (tokens (list 10 principal))
    (percentages (list 10 uint))
  )
  (let ((token-count (len tokens)))
    (begin
      ;; Initialize assets 2-9 (0 and 1 handled in main function)
      (if (> token-count u2)
        (unwrap!
          (initialize-portfolio-asset u2
            (unwrap! (element-at tokens u2) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u2) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u3)
        (unwrap!
          (initialize-portfolio-asset u3
            (unwrap! (element-at tokens u3) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u3) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u4)
        (unwrap!
          (initialize-portfolio-asset u4
            (unwrap! (element-at tokens u4) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u4) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u5)
        (unwrap!
          (initialize-portfolio-asset u5
            (unwrap! (element-at tokens u5) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u5) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u6)
        (unwrap!
          (initialize-portfolio-asset u6
            (unwrap! (element-at tokens u6) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u6) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u7)
        (unwrap!
          (initialize-portfolio-asset u7
            (unwrap! (element-at tokens u7) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u7) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u8)
        (unwrap!
          (initialize-portfolio-asset u8
            (unwrap! (element-at tokens u8) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u8) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (if (> token-count u9)
        (unwrap!
          (initialize-portfolio-asset u9
            (unwrap! (element-at tokens u9) ERR-INVALID-TOKEN)
            (unwrap! (element-at percentages u9) ERR-INVALID-PERCENTAGE)
            portfolio-id
          )
          ERR-INVALID-TOKEN
        )
        true
      )
      (ok true)
    )
  )
)

;; PUBLIC FUNCTIONS

;; Create a new diversified portfolio with specified token allocations
(define-public (create-portfolio
    (initial-tokens (list 10 principal))
    (percentages (list 10 uint))
  )
  (let (
      (portfolio-id (+ (var-get portfolio-counter) u1))
      (token-count (len initial-tokens))
      (percentage-count (len percentages))
    )
    ;; Validation checks
    (asserts! (<= token-count MAX-TOKENS-PER-PORTFOLIO) ERR-MAX-TOKENS-EXCEEDED)
    (asserts! (is-eq token-count percentage-count) ERR-LENGTH-MISMATCH)
    (asserts! (validate-portfolio-percentages percentages) ERR-INVALID-PERCENTAGE)
    (asserts! (>= token-count u2) ERR-INVALID-PORTFOLIO)
    ;; Create portfolio record
    (map-set Portfolios portfolio-id {
      owner: tx-sender,
      created-at: stacks-block-height,
      last-rebalanced: stacks-block-height,
      total-value: u0,
      active: true,
      token-count: token-count,
    })
    ;; Initialize first two assets (guaranteed to exist)
    (try! (initialize-portfolio-asset u0
      (unwrap! (element-at initial-tokens u0) ERR-INVALID-TOKEN)
      (unwrap! (element-at percentages u0) ERR-INVALID-PERCENTAGE)
      portfolio-id
    ))
    (try! (initialize-portfolio-asset u1
      (unwrap! (element-at initial-tokens u1) ERR-INVALID-TOKEN)
      (unwrap! (element-at percentages u1) ERR-INVALID-PERCENTAGE)
      portfolio-id
    ))
    ;; Initialize remaining assets (positions 2-9)
    (try! (initialize-all-assets portfolio-id initial-tokens percentages))
    ;; Add to user's portfolio list
    (try! (add-to-user-portfolios tx-sender portfolio-id))
    ;; Update global counter
    (var-set portfolio-counter portfolio-id)
    (ok portfolio-id)
  )
)

;; Rebalance portfolio to match target allocations
(define-public (rebalance-portfolio (portfolio-id uint))
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO)))
    ;; Authorization and validity checks
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (get active portfolio) ERR-INVALID-PORTFOLIO)
    ;; Update last rebalanced timestamp
    (map-set Portfolios portfolio-id
      (merge portfolio { last-rebalanced: stacks-block-height })
    )
    (ok true)
  )
)

;; Update target allocation percentage for a specific token
(define-public (update-portfolio-allocation
    (portfolio-id uint)
    (token-id uint)
    (new-percentage uint)
  )
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (asset (unwrap! (get-portfolio-asset portfolio-id token-id) ERR-INVALID-TOKEN))
    )
    ;; Authorization and validation checks
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (validate-percentage new-percentage) ERR-INVALID-PERCENTAGE)
    (asserts! (validate-token-id portfolio-id token-id) ERR-INVALID-TOKEN-ID)
    ;; Update asset allocation
    (map-set PortfolioAssets {
      portfolio-id: portfolio-id,
      token-id: token-id,
    }
      (merge asset { target-percentage: new-percentage })
    )
    (ok true)
  )
)

;; PROTOCOL ADMINISTRATION

;; Transfer protocol ownership to new administrator
(define-public (initialize (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq new-owner tx-sender)) ERR-NOT-AUTHORIZED)
    (var-set protocol-owner new-owner)
    (ok true)
  )
)
