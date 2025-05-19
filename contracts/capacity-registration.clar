;; Capacity Registration Contract
;; Records production capabilities of manufacturers

(define-map production-capacity
  { entity-id: principal, product-id: (string-ascii 50) }
  {
    max-capacity: uint,
    current-utilization: uint,
    last-updated: uint
  }
)

(define-map product-registry
  (string-ascii 50)
  {
    name: (string-ascii 100),
    category: (string-ascii 50),
    registered-by: principal
  }
)

(define-read-only (get-capacity (entity-id principal) (product-id (string-ascii 50)))
  (default-to
    {
      max-capacity: u0,
      current-utilization: u0,
      last-updated: u0
    }
    (map-get? production-capacity { entity-id: entity-id, product-id: product-id })
  )
)

(define-read-only (get-product (product-id (string-ascii 50)))
  (map-get? product-registry product-id)
)

(define-public (register-product (product-id (string-ascii 50)) (name (string-ascii 100)) (category (string-ascii 50)))
  (begin
    (asserts! (is-none (get-product product-id)) (err u1)) ;; Product ID must be unique
    (ok (map-set product-registry product-id
      {
        name: name,
        category: category,
        registered-by: tx-sender
      }
    ))
  )
)

(define-public (register-capacity (product-id (string-ascii 50)) (max-capacity uint))
  (begin
    (asserts! (is-some (get-product product-id)) (err u2)) ;; Product must exist
    (ok (map-set production-capacity
      { entity-id: tx-sender, product-id: product-id }
      {
        max-capacity: max-capacity,
        current-utilization: u0,
        last-updated: block-height
      }
    ))
  )
)

(define-public (update-utilization (product-id (string-ascii 50)) (utilization uint))
  (let ((current-capacity (get-capacity tx-sender product-id)))
    (asserts! (> (get max-capacity current-capacity) u0) (err u3)) ;; Capacity must be registered
    (asserts! (<= utilization (get max-capacity current-capacity)) (err u4)) ;; Cannot exceed max capacity
    (ok (map-set production-capacity
      { entity-id: tx-sender, product-id: product-id }
      {
        max-capacity: (get max-capacity current-capacity),
        current-utilization: utilization,
        last-updated: block-height
      }
    ))
  )
)

(define-read-only (get-available-capacity (entity-id principal) (product-id (string-ascii 50)))
  (let ((capacity-data (get-capacity entity-id product-id)))
    (- (get max-capacity capacity-data) (get current-utilization capacity-data))
  )
)
