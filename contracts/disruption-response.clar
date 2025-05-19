;; Disruption Response Contract
;; Coordinates supply chain adjustments during disruptions

(define-map disruption-events
  uint
  {
    reporter: principal,
    description: (string-ascii 500),
    affected-products: (list 10 (string-ascii 50)),
    severity: uint,  ;; 1-10 scale
    start-time: uint,
    resolution-time: uint,  ;; 0 if ongoing
    status: uint  ;; 0=reported, 1=verified, 2=in-progress, 3=resolved
  }
)

(define-map response-actions
  { disruption-id: uint, action-id: uint }
  {
    action-type: (string-ascii 50),  ;; e.g., "activate-alternative", "reduce-production"
    target-entity: principal,
    product-id: (string-ascii 50),
    parameters: (string-ascii 200),  ;; JSON-encoded parameters
    status: uint,  ;; 0=planned, 1=in-progress, 2=completed, 3=failed
    created-at: uint,
    updated-at: uint
  }
)

(define-data-var disruption-count uint u0)
(define-map action-counts uint uint)  ;; disruption-id -> action count

(define-read-only (get-disruption (disruption-id uint))
  (map-get? disruption-events disruption-id)
)

(define-read-only (get-response-action (disruption-id uint) (action-id uint))
  (map-get? response-actions { disruption-id: disruption-id, action-id: action-id })
)

(define-public (report-disruption
    (description (string-ascii 500))
    (affected-products (list 10 (string-ascii 50)))
    (severity uint)
  )
  (let ((new-disruption-id (+ (var-get disruption-count) u1)))
    (asserts! (<= severity u10) (err u1)) ;; Severity must be 1-10
    (asserts! (> severity u0) (err u2)) ;; Severity must be greater than 0

    (var-set disruption-count new-disruption-id)
    (map-set action-counts new-disruption-id u0)

    (ok (map-set disruption-events new-disruption-id
      {
        reporter: tx-sender,
        description: description,
        affected-products: affected-products,
        severity: severity,
        start-time: block-height,
        resolution-time: u0,
        status: u0  ;; Reported
      }
    ))
  )
)

(define-public (verify-disruption (disruption-id uint))
  (let ((disruption (unwrap! (get-disruption disruption-id) (err u3))))
    (ok (map-set disruption-events disruption-id
      (merge disruption { status: u1 })  ;; Verified
    ))
  )
)

(define-public (create-response-action
    (disruption-id uint)
    (action-type (string-ascii 50))
    (target-entity principal)
    (product-id (string-ascii 50))
    (parameters (string-ascii 200))
  )
  (let (
    (disruption (unwrap! (get-disruption disruption-id) (err u3)))
    (current-action-count (default-to u0 (map-get? action-counts disruption-id)))
    (new-action-id (+ current-action-count u1))
  )
    (asserts! (> (get status disruption) u0) (err u4)) ;; Disruption must be verified
    (asserts! (< (get status disruption) u3) (err u5)) ;; Disruption must not be resolved

    (map-set action-counts disruption-id new-action-id)

    (ok (map-set response-actions
      { disruption-id: disruption-id, action-id: new-action-id }
      {
        action-type: action-type,
        target-entity: target-entity,
        product-id: product-id,
        parameters: parameters,
        status: u0,  ;; Planned
        created-at: block-height,
        updated-at: block-height
      }
    ))
  )
)

(define-public (update-action-status (disruption-id uint) (action-id uint) (new-status uint))
  (let ((action (unwrap! (get-response-action disruption-id action-id) (err u6))))
    (asserts! (<= new-status u3) (err u7)) ;; Valid status values: 0-3

    (ok (map-set response-actions
      { disruption-id: disruption-id, action-id: action-id }
      (merge action {
        status: new-status,
        updated-at: block-height
      })
    ))
  )
)

(define-public (resolve-disruption (disruption-id uint))
  (let ((disruption (unwrap! (get-disruption disruption-id) (err u3))))
    (asserts! (is-eq (get resolution-time disruption) u0) (err u8)) ;; Must not be already resolved

    (ok (map-set disruption-events disruption-id
      (merge disruption {
        resolution-time: block-height,
        status: u3  ;; Resolved
      })
    ))
  )
)
