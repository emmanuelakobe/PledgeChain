;; PledgeChain Smart Contract
;; A contract for creating and managing accountability pledges

;; ---------------------------------------------
;; Error Constants
;; ---------------------------------------------
(define-constant ERR-ZERO-STX (err u100))
(define-constant ERR-NOT-OWNER (err u101))
(define-constant ERR-NOT-ACTIVE (err u102))
(define-constant ERR-CHECKIN-WINDOW (err u103))
(define-constant ERR-ALREADY-CHECKED-IN (err u104))
(define-constant ERR-NOT-FOUND (err u105))
(define-constant ERR-INVALID-DURATION (err u106))
(define-constant ERR-INVALID-INTERVAL (err u107))

;; ---------------------------------------------
;; Data Variables
;; ---------------------------------------------
(define-data-var next-id uint u1)

;; ---------------------------------------------
;; Data Maps
;; ---------------------------------------------
(define-map pledges uint {
  pledger: principal,
  description: (string-utf8 100),
  start-block: uint,
  duration: uint,
  interval: uint,
  next-checkin: uint,
  last-checkin: uint,
  penalty-address: principal,
  amount: uint,
  status: (string-ascii 10)
})

(define-map checkins { pledge-id: uint, checkin-block: uint } bool)

;; ---------------------------------------------
;; Public: Create a new pledge
;; ---------------------------------------------
(define-public (create-pledge
    (description (string-utf8 100))
    (duration uint)
    (interval uint)
    (penalty-address principal)
    (amount uint)
)
  (begin
    ;; Input validation
    (asserts! (> amount u0) ERR-ZERO-STX)
    (asserts! (> duration u0) ERR-INVALID-DURATION)
    (asserts! (> interval u0) ERR-INVALID-INTERVAL)
    
    (let (
      (pledge-id (var-get next-id))
      (sender tx-sender)
      (current-block stacks-block-height)
    )
      (begin
        ;; Transfer STX to contract
        (try! (stx-transfer? amount sender (as-contract tx-sender)))

        ;; Store pledge data
        (map-set pledges pledge-id {
          pledger: sender,
          description: description,
          start-block: current-block,
          duration: duration,
          interval: interval,
          next-checkin: (+ current-block interval),
          last-checkin: current-block,
          penalty-address: penalty-address,
          amount: amount,
          status: "active"
        })
        
        ;; Increment next ID
        (var-set next-id (+ pledge-id u1))
        (ok pledge-id)
      )
    )
  )
)

;; ---------------------------------------------
;; Public: Check in to maintain your pledge
;; ---------------------------------------------
(define-public (check-in (pledge-id uint))
  (let (
    (pledge (map-get? pledges pledge-id))
    (now stacks-block-height)
  )
    (match pledge pledge-data
      (begin
        ;; Verify ownership and status
        (asserts! (is-eq (get pledger pledge-data) tx-sender) ERR-NOT-OWNER)
        (asserts! (is-eq (get status pledge-data) "active") ERR-NOT-ACTIVE)
        (asserts! (>= now (get next-checkin pledge-data)) ERR-CHECKIN-WINDOW)

        (let ((checkin-key { pledge-id: pledge-id, checkin-block: now }))
          ;; Ensure not already checked in for this block
          (asserts! (is-none (map-get? checkins checkin-key)) ERR-ALREADY-CHECKED-IN)
          
          ;; Record the check-in
          (map-set checkins checkin-key true)

          ;; Update pledge with new check-in time
          (map-set pledges pledge-id (merge pledge-data {
            last-checkin: now,
            next-checkin: (+ now (get interval pledge-data))
          }))
          (ok true)
        )
      )
      ERR-NOT-FOUND
    )
  )
)

;; ---------------------------------------------
;; Read-only: Get pledge details
;; ---------------------------------------------
(define-read-only (get-pledge (pledge-id uint))
  (map-get? pledges pledge-id)
)

;; ---------------------------------------------
;; Read-only: Check if checked in for specific block
;; ---------------------------------------------
(define-read-only (has-checked-in (pledge-id uint) (checkin-block uint))
  (default-to false (map-get? checkins { pledge-id: pledge-id, checkin-block: checkin-block }))
)