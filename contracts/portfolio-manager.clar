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