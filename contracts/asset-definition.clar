;; Asset Definition Contract
;; Records derivative parameters and manages synthetic assets

(define-data-var admin principal tx-sender)
(define-map synthetic-assets uint (tuple (name (string-ascii 32)) (symbol (string-ascii 8)) (oracle-contract principal) (collateral-ratio uint)))
(define-data-var next-asset-id uint u1)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-PARAMS u101)
(define-constant ERR-ASSET-EXISTS u102)
(define-constant ERR-ASSET-NOT-FOUND u103)

;; Read-only functions
(define-read-only (get-asset (asset-id uint))
  (map-get? synthetic-assets asset-id)
)

(define-read-only (get-next-asset-id)
  (var-get next-asset-id)
)

;; Public functions
(define-public (create-synthetic-asset (name (string-ascii 32)) (symbol (string-ascii 8)) (oracle-contract principal) (collateral-ratio uint))
  (let ((asset-id (var-get next-asset-id)))
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (> collateral-ratio u100) (err ERR-INVALID-PARAMS))
    (asserts! (is-none (map-get? synthetic-assets asset-id)) (err ERR-ASSET-EXISTS))

    (var-set next-asset-id (+ asset-id u1))
    (ok (map-set synthetic-assets
                asset-id
                (tuple (name name) (symbol symbol) (oracle-contract oracle-contract) (collateral-ratio collateral-ratio))))
  )
)

(define-public (update-asset-params (asset-id uint) (collateral-ratio uint))
  (let ((asset (map-get? synthetic-assets asset-id)))
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-some asset) (err ERR-ASSET-NOT-FOUND))
    (asserts! (> collateral-ratio u100) (err ERR-INVALID-PARAMS))

    (ok (map-set synthetic-assets
                asset-id
                (merge (unwrap-panic asset) (tuple (collateral-ratio collateral-ratio)))))
  )
)

;; Private functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get admin))
)
