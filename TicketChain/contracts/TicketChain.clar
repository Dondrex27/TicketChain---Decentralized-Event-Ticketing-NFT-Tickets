;; TicketChain - Decentralized Event Ticketing & NFT Tickets
;; Prevents scalping, enables resale controls, and provides verifiable ownership

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-sold-out (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-event-passed (err u105))
(define-constant err-already-used (err u106))
(define-constant err-transfer-disabled (err u107))

(define-constant max-resale-markup u150) ;; 150% max resale price

(define-data-var next-event-id uint u1)
(define-data-var next-ticket-id uint u1)
(define-data-var next-attendee-id uint u1)
(define-data-var total-revenue uint u0)
(define-data-var platform-fee-percent uint u3)

(define-map events
  uint
  {
    organizer: principal,
    name: (string-ascii 128),
    venue: (string-ascii 128),
    event-date: uint,
    total-tickets: uint,
    sold-tickets: uint,
    base-price: uint,
    resale-enabled: bool,
    active: bool,
    created-at: uint
  }
)

(define-map tickets
  uint
  {
    event-id: uint,
    owner: principal,
    purchase-price: uint,
    used: bool,
    resale-price: (optional uint),
    transferred-count: uint,
    created-at: uint
  }
)

(define-map user-tickets
  {user: principal, event-id: uint}
  (list 10 uint)
)

(define-map event-attendees
  uint
  {
    ticket-id: uint,
    attendee: principal,
    check-in-time: uint,
    verified: bool
  }
)

(define-map organizer-stats
  principal
  {
    total-events: uint,
    total-tickets-sold: uint,
    total-earnings: uint
  }
)

(define-map ticket-transfers
  uint
  {
    ticket-id: uint,
    from: principal,
    to: principal,
    price: uint,
    timestamp: uint
  }
)

(define-public (create-event
    (name (string-ascii 128))
    (venue (string-ascii 128))
    (event-date uint)
    (total-tickets uint)
    (base-price uint)
    (resale-enabled bool))
  (let ((event-id (var-get next-event-id)))
    (asserts! (> total-tickets u0) err-invalid-price)
    (asserts! (> base-price u0) err-invalid-price)
    (asserts! (> event-date block-height) err-event-passed)

    (map-set events event-id {
      organizer: tx-sender,
      name: name,
      venue: venue,
      event-date: event-date,
      total-tickets: total-tickets,
      sold-tickets: u0,
      base-price: base-price,
      resale-enabled: resale-enabled,
      active: true,
      created-at: block-height
    })

    (var-set next-event-id (+ event-id u1))
    (print {event: "event-created", event-id: event-id, organizer: tx-sender})
    (ok event-id)
  )
)

(define-public (purchase-ticket (event-id uint))
  (let (
    (event-info (unwrap! (map-get? events event-id) err-not-found))
    (ticket-id (var-get next-ticket-id))
  )
    (asserts! (get active event-info) err-unauthorized)
    (asserts! (< (get sold-tickets event-info) (get total-tickets event-info)) err-sold-out)
    (asserts! (> (get event-date event-info) block-height) err-event-passed)

    (map-set tickets ticket-id {
      event-id: event-id,
      owner: tx-sender,
      purchase-price: (get base-price event-info),
      used: false,
      resale-price: none,
      transferred-count: u0,
      created-at: block-height
    })

    (map-set events event-id
      (merge event-info {sold-tickets: (+ (get sold-tickets event-info) u1)}))

    (var-set next-ticket-id (+ ticket-id u1))
    (var-set total-revenue (+ (var-get total-revenue) (get base-price event-info)))

    (print {event: "ticket-purchased", ticket-id: ticket-id, buyer: tx-sender})
    (ok ticket-id)
  )
)

(define-public (list-for-resale (ticket-id uint) (resale-price uint))
  (let ((ticket (unwrap! (map-get? tickets ticket-id) err-not-found)))
    (asserts! (is-eq (get owner ticket) tx-sender) err-unauthorized)
    (asserts! (not (get used ticket)) err-already-used)

    (let ((event-info (unwrap! (map-get? events (get event-id ticket)) err-not-found)))
      (asserts! (get resale-enabled event-info) err-transfer-disabled)
      (asserts! (<= resale-price (* (get purchase-price ticket) max-resale-markup)) err-invalid-price)

      (map-set tickets ticket-id (merge ticket {resale-price: (some resale-price)}))
      (print {event: "ticket-listed", ticket-id: ticket-id, price: resale-price})
      (ok true)
    )
  )
)

(define-public (buy-resale-ticket (ticket-id uint))
  (let ((ticket (unwrap! (map-get? tickets ticket-id) err-not-found)))
    (asserts! (is-some (get resale-price ticket)) err-not-found)
    (asserts! (not (get used ticket)) err-already-used)

    (map-set tickets ticket-id
      (merge ticket {
        owner: tx-sender,
        resale-price: none,
        transferred-count: (+ (get transferred-count ticket) u1)
      }))

    (print {event: "ticket-resold", ticket-id: ticket-id, new-owner: tx-sender})
    (ok true)
  )
)

(define-public (use-ticket (ticket-id uint))
  (let ((ticket (unwrap! (map-get? tickets ticket-id) err-not-found)))
    (asserts! (is-eq (get owner ticket) tx-sender) err-unauthorized)
    (asserts! (not (get used ticket)) err-already-used)

    (map-set tickets ticket-id (merge ticket {used: true}))
    (print {event: "ticket-used", ticket-id: ticket-id})
    (ok true)
  )
)

(define-read-only (get-event (event-id uint))
  (map-get? events event-id)
)

(define-read-only (get-ticket (ticket-id uint))
  (map-get? tickets ticket-id)
)

(define-read-only (get-platform-revenue)
  (ok (var-get total-revenue))
)

(define-public (cancel-event (event-id uint))
  (let ((event-info (unwrap! (map-get? events event-id) err-not-found)))
    (asserts! (is-eq tx-sender (get organizer event-info)) err-unauthorized)
    (asserts! (get active event-info) err-unauthorized)

    (map-set events event-id (merge event-info {active: false}))

    (print {event: "event-cancelled", event-id: event-id})
    (ok true)
  )
)

(define-public (update-event-date (event-id uint) (new-date uint))
  (let ((event-info (unwrap! (map-get? events event-id) err-not-found)))
    (asserts! (is-eq tx-sender (get organizer event-info)) err-unauthorized)
    (asserts! (> new-date block-height) err-event-passed)

    (map-set events event-id (merge event-info {event-date: new-date}))

    (print {event: "event-date-updated", event-id: event-id, new-date: new-date})
    (ok true)
  )
)

(define-public (gift-ticket (ticket-id uint) (recipient principal))
  (let ((ticket (unwrap! (map-get? tickets ticket-id) err-not-found)))
    (asserts! (is-eq (get owner ticket) tx-sender) err-unauthorized)
    (asserts! (not (get used ticket)) err-already-used)

    (map-set tickets ticket-id
      (merge ticket {
        owner: recipient,
        transferred-count: (+ (get transferred-count ticket) u1)
      }))

    (print {event: "ticket-gifted", ticket-id: ticket-id, from: tx-sender, to: recipient})
    (ok true)
  )
)

(define-public (verify-ticket (ticket-id uint))
  (let (
    (ticket (unwrap! (map-get? tickets ticket-id) err-not-found))
    (event-info (unwrap! (map-get? events (get event-id ticket)) err-not-found))
    (attendee-id (var-get next-attendee-id))
  )
    (asserts! (is-eq tx-sender (get organizer event-info)) err-unauthorized)
    (asserts! (not (get used ticket)) err-already-used)

    (map-set event-attendees attendee-id {
      ticket-id: ticket-id,
      attendee: (get owner ticket),
      check-in-time: block-height,
      verified: true
    })

    (var-set next-attendee-id (+ attendee-id u1))

    (print {event: "ticket-verified", ticket-id: ticket-id, attendee-id: attendee-id})
    (ok attendee-id)
  )
)

(define-public (cancel-listing (ticket-id uint))
  (let ((ticket (unwrap! (map-get? tickets ticket-id) err-not-found)))
    (asserts! (is-eq (get owner ticket) tx-sender) err-unauthorized)
    (asserts! (is-some (get resale-price ticket)) err-not-found)

    (map-set tickets ticket-id (merge ticket {resale-price: none}))

    (print {event: "listing-cancelled", ticket-id: ticket-id})
    (ok true)
  )
)

(define-read-only (get-organizer-stats (organizer principal))
  (map-get? organizer-stats organizer)
)

(define-read-only (get-attendee (attendee-id uint))
  (map-get? event-attendees attendee-id)
)

(define-read-only (get-event-stats (event-id uint))
  (match (map-get? events event-id)
    event-info (ok {
      sold: (get sold-tickets event-info),
      total: (get total-tickets event-info),
      revenue: (* (get sold-tickets event-info) (get base-price event-info))
    })
    err-not-found
  )
)
