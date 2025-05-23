;; Oracle Verification Contract
;; Validates data providers and ensures data integrity

(define-data-var admin principal tx-sender)
(define-map authorized-oracles principal bool)
(define-map oracle-data (tuple (asset-id uint) (timestamp uint)) (tuple (price uint) (provider principal)))

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-DATA u101)

;; Read-only functions
(define-read-only (is-authorized-oracle (provider principal))
  (default-to false (map-get? authorized-oracles provider))
)

(define-read-only (get-price-data (asset-id uint) (timestamp uint))
  (map-get? oracle-data (tuple (asset-id asset-id) (timestamp timestamp)))
)

;; Public functions
(define-public (register-oracle (provider principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (ok (map-set authorized-oracles provider true))
  )
)

(define-public (remove-oracle (provider principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (ok (map-delete authorized-oracles provider))
  )
)

(define-public (submit-price-data (asset-id uint) (price uint))
  (let ((timestamp (get-block-info? time (- block-height u1))))
    (asserts! (is-authorized-oracle tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (> price u0) (err ERR-INVALID-DATA))
    (asserts! (is-some timestamp) (err ERR-INVALID-DATA))
    (ok (map-set oracle-data
                (tuple (asset-id asset-id) (timestamp (unwrap-panic timestamp)))
                (tuple (price price) (provider tx-sender))))
  )
)

;; Private functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get admin))
)

;; Contract initialization
(map-set authorized-oracles tx-sender true)
