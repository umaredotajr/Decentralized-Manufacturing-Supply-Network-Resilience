;; Risk Assessment Contract
;; Identifies potential disruption factors

(define-map risk-factors
  uint
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    severity: uint,  ;; 1-10 scale
    registered-by: principal,
    registration-time: uint
  }
)

(define-map entity-risk-exposure
  { entity-id: principal, risk-id: uint }
  {
    exposure-level: uint,  ;; 1-10 scale
    last-assessed: uint
  }
)

(define-data-var risk-factor-count uint u0)

(define-read-only (get-risk-factor (risk-id uint))
  (map-get? risk-factors risk-id)
)

(define-read-only (get-entity-exposure (entity-id principal) (risk-id uint))
  (default-to
    { exposure-level: u0, last-assessed: u0 }
    (map-get? entity-risk-exposure { entity-id: entity-id, risk-id: risk-id })
  )
)

(define-public (register-risk-factor
    (name (string-ascii 100))
    (description (string-ascii 500))
    (category (string-ascii 50))
    (severity uint)
  )
  (let ((new-risk-id (+ (var-get risk-factor-count) u1)))
    (asserts! (<= severity u10) (err u1)) ;; Severity must be 1-10
    (asserts! (> severity u0) (err u2)) ;; Severity must be greater than 0
    (var-set risk-factor-count new-risk-id)
    (ok (map-set risk-factors new-risk-id
      {
        name: name,
        description: description,
        category: category,
        severity: severity,
        registered-by: tx-sender,
        registration-time: block-height
      }
    ))
  )
)

(define-public (assess-entity-risk (entity-id principal) (risk-id uint) (exposure-level uint))
  (begin
    (asserts! (is-some (get-risk-factor risk-id)) (err u3)) ;; Risk factor must exist
    (asserts! (<= exposure-level u10) (err u1)) ;; Exposure must be 1-10
    (asserts! (> exposure-level u0) (err u2)) ;; Exposure must be greater than 0
    (ok (map-set entity-risk-exposure
      { entity-id: entity-id, risk-id: risk-id }
      {
        exposure-level: exposure-level,
        last-assessed: block-height
      }
    ))
  )
)

(define-read-only (calculate-overall-risk (entity-id principal))
  (let (
    (risk-count (var-get risk-factor-count))
    (total-risk u0)
    (assessed-risks u0)
  )
    ;; This is a simplified calculation - in a real implementation,
    ;; we would iterate through all risks and calculate a weighted average
    ;; Since Clarity doesn't support loops, this would need to be implemented
    ;; with a more complex approach or off-chain calculation

    ;; For demonstration, we'll return a placeholder value
    u5
  )
)
