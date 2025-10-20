(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-NOT-ELIGIBLE (err u403))
(define-constant ERR-MESSAGE-NOT-FOUND (err u19))
(define-constant ERR-THREAD-NOT-FOUND (err u20))
(define-constant ERR-UNAUTHORIZED-MESSAGE-ACCESS (err u21))
(define-constant ERR-INVALID-MESSAGE-CONTENT (err u22))
(define-constant ERR-MESSAGE-TOO-LONG (err u23))

(define-data-var contract-active bool true)
(define-data-var session-fee uint u1000000)
(define-data-var next-session-id uint u0)
(define-data-var verification-threshold-rating uint u4)
(define-data-var verification-threshold-sessions uint u10)

;; Messaging System Data Variables
(define-data-var thread-id-nonce uint u0)
(define-data-var message-id-nonce uint u0)

(define-map student-profiles
    principal
    {
        name: (string-ascii 50),
        skills-wanted: (list 10 (string-ascii 30)),
        experience-level: (string-ascii 20),
        hourly-budget: uint,
        rating: uint,
        total-sessions: uint,
        created-at: uint,
    }
)

(define-map mentor-profiles
    principal
    {
        name: (string-ascii 50),
        skills-offered: (list 10 (string-ascii 30)),
        experience-years: uint,
        hourly-rate: uint,
        rating: uint,
        total-sessions: uint,
        active: bool,
        verified: bool,
        verification-date: uint,
        created-at: uint,
    }
)

(define-map sessions
    uint
    {
        student: principal,
        mentor: principal,
        skill: (string-ascii 30),
        status: (string-ascii 20),
        scheduled-time: uint,
        duration: uint,
        fee: uint,
        created-at: uint,
    }
)

(define-map session-reviews
    uint
    {
        reviewer: principal,
        rating: uint,
        comment: (string-ascii 200),
        created-at: uint,
    }
)

(define-map mentor-availability
    principal
    {
        available-times: (list 20 uint),
        timezone: (string-ascii 10),
        updated-at: uint,
    }
)

(define-map skill-matches
    {
        student: principal,
        mentor: principal,
    }
    {
        matching-skills: (list 10 (string-ascii 30)),
        compatibility-score: uint,
        created-at: uint,
    }
)

;; Messaging System Data Maps
(define-map message-threads
    { thread-id: uint }
    {
        participant-1: principal,
        participant-2: principal,
        created-at: uint,
        last-message-at: uint,
        message-count: uint,
    }
)

(define-map messages
    { message-id: uint }
    {
        thread-id: uint,
        sender: principal,
        content: (string-utf8 500),
        sent-at: uint,
        is-read: bool,
    }
)

(define-map user-thread-mapping
    { user-1: principal, user-2: principal }
    { thread-id: uint }
)

(define-read-only (get-student-profile (student principal))
    (map-get? student-profiles student)
)

(define-read-only (get-mentor-profile (mentor principal))
    (map-get? mentor-profiles mentor)
)

(define-read-only (get-session (session-id uint))
    (map-get? sessions session-id)
)

(define-read-only (get-session-review (session-id uint))
    (map-get? session-reviews session-id)
)

(define-read-only (get-mentor-availability (mentor principal))
    (map-get? mentor-availability mentor)
)

(define-read-only (get-skill-match
        (student principal)
        (mentor principal)
    )
    (map-get? skill-matches {
        student: student,
        mentor: mentor,
    })
)

(define-read-only (is-contract-active)
    (var-get contract-active)
)

(define-read-only (get-session-fee)
    (var-get session-fee)
)

(define-read-only (get-next-session-id)
    (var-get next-session-id)
)

(define-read-only (get-verification-thresholds)
    {
        rating: (var-get verification-threshold-rating),
        sessions: (var-get verification-threshold-sessions),
    }
)

(define-read-only (is-mentor-eligible-for-verification (mentor principal))
    (match (map-get? mentor-profiles mentor)
        profile (and
            (>= (get rating profile) (var-get verification-threshold-rating))
            (>= (get total-sessions profile)
                (var-get verification-threshold-sessions)
            )
            (not (get verified profile))
        )
        false
    )
)

;; Messaging System Read-Only Functions
(define-read-only (get-thread-details (thread-id uint))
    (map-get? message-threads { thread-id: thread-id })
)

(define-read-only (get-message-details (message-id uint))
    (map-get? messages { message-id: message-id })
)

(define-read-only (get-user-thread
        (user-1 principal)
        (user-2 principal)
    )
    (let (
            (mapping-1 (map-get? user-thread-mapping { user-1: user-1, user-2: user-2 }))
            (mapping-2 (map-get? user-thread-mapping { user-1: user-2, user-2: user-1 }))
        )
        (if (is-some mapping-1)
            mapping-1
            mapping-2
        )
    )
)

(define-read-only (get-thread-messages-count (thread-id uint))
    (match (map-get? message-threads { thread-id: thread-id })
        thread (ok (get message-count thread))
        ERR-THREAD-NOT-FOUND
    )
)

(define-read-only (get-next-thread-id)
    (var-get thread-id-nonce)
)

(define-read-only (get-next-message-id)
    (var-get message-id-nonce)
)

(define-public (create-student-profile
        (name (string-ascii 50))
        (skills-wanted (list 10 (string-ascii 30)))
        (experience-level (string-ascii 20))
        (hourly-budget uint)
    )
    (let ((student tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
        (asserts! (> (len skills-wanted) u0) ERR-INVALID-PARAMS)
        (asserts! (> hourly-budget u0) ERR-INVALID-PARAMS)
        (asserts! (is-none (map-get? student-profiles student))
            ERR-ALREADY-EXISTS
        )
        (ok (map-set student-profiles student {
            name: name,
            skills-wanted: skills-wanted,
            experience-level: experience-level,
            hourly-budget: hourly-budget,
            rating: u0,
            total-sessions: u0,
            created-at: stacks-block-height,
        }))
    )
)

(define-public (create-mentor-profile
        (name (string-ascii 50))
        (skills-offered (list 10 (string-ascii 30)))
        (experience-years uint)
        (hourly-rate uint)
    )
    (let ((mentor tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
        (asserts! (> (len skills-offered) u0) ERR-INVALID-PARAMS)
        (asserts! (> hourly-rate u0) ERR-INVALID-PARAMS)
        (asserts! (is-none (map-get? mentor-profiles mentor)) ERR-ALREADY-EXISTS)
        (ok (map-set mentor-profiles mentor {
            name: name,
            skills-offered: skills-offered,
            experience-years: experience-years,
            hourly-rate: hourly-rate,
            rating: u0,
            total-sessions: u0,
            active: true,
            verified: false,
            verification-date: u0,
            created-at: stacks-block-height,
        }))
    )
)

(define-public (update-student-profile
        (name (string-ascii 50))
        (skills-wanted (list 10 (string-ascii 30)))
        (experience-level (string-ascii 20))
        (hourly-budget uint)
    )
    (let ((student tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
        (asserts! (> hourly-budget u0) ERR-INVALID-PARAMS)
        (asserts! (is-some (map-get? student-profiles student)) ERR-NOT-FOUND)
        (match (map-get? student-profiles student)
            profile (ok (map-set student-profiles student
                (merge profile {
                    name: name,
                    skills-wanted: skills-wanted,
                    experience-level: experience-level,
                    hourly-budget: hourly-budget,
                })
            ))
            ERR-NOT-FOUND
        )
    )
)

(define-public (update-mentor-profile
        (name (string-ascii 50))
        (skills-offered (list 10 (string-ascii 30)))
        (experience-years uint)
        (hourly-rate uint)
    )
    (let ((mentor tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
        (asserts! (> hourly-rate u0) ERR-INVALID-PARAMS)
        (asserts! (is-some (map-get? mentor-profiles mentor)) ERR-NOT-FOUND)
        (match (map-get? mentor-profiles mentor)
            profile (ok (map-set mentor-profiles mentor
                (merge profile {
                    name: name,
                    skills-offered: skills-offered,
                    experience-years: experience-years,
                    hourly-rate: hourly-rate,
                })
            ))
            ERR-NOT-FOUND
        )
    )
)

(define-public (toggle-mentor-availability)
    (let ((mentor tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? mentor-profiles mentor)) ERR-NOT-FOUND)
        (match (map-get? mentor-profiles mentor)
            profile (ok (map-set mentor-profiles mentor
                (merge profile { active: (not (get active profile)) })
            ))
            ERR-NOT-FOUND
        )
    )
)

(define-public (set-mentor-availability
        (available-times (list 20 uint))
        (timezone (string-ascii 10))
    )
    (let ((mentor tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? mentor-profiles mentor)) ERR-NOT-FOUND)
        (asserts! (> (len available-times) u0) ERR-INVALID-PARAMS)
        (ok (map-set mentor-availability mentor {
            available-times: available-times,
            timezone: timezone,
            updated-at: stacks-block-height,
        }))
    )
)

(define-private (calculate-skill-match
        (student-skills (list 10 (string-ascii 30)))
        (mentor-skills (list 10 (string-ascii 30)))
    )
    (let ((matching-skills (filter is-skill-match (map create-skill-pair student-skills))))
        {
            matching-skills: (map unwrap-skill matching-skills),
            compatibility-score: (len matching-skills),
        }
    )
)

(define-private (create-skill-pair (skill (string-ascii 30)))
    (some skill)
)

(define-private (is-skill-match (skill (optional (string-ascii 30))))
    (is-some skill)
)

(define-private (unwrap-skill (skill (optional (string-ascii 30))))
    (unwrap-panic skill)
)

(define-public (find-mentor-matches (student principal))
    (let ((student-profile (unwrap! (map-get? student-profiles student) ERR-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (ok (get skills-wanted student-profile))
    )
)

(define-public (create-session
        (mentor principal)
        (skill (string-ascii 30))
        (scheduled-time uint)
        (duration uint)
    )
    (let (
            (student tx-sender)
            (session-id (var-get next-session-id))
            (mentor-profile (unwrap! (map-get? mentor-profiles mentor) ERR-NOT-FOUND))
            (student-profile (unwrap! (map-get? student-profiles student) ERR-NOT-FOUND))
            (session-cost (* (get hourly-rate mentor-profile) duration))
        )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (get active mentor-profile) ERR-UNAUTHORIZED)
        (asserts! (>= (get hourly-budget student-profile) session-cost)
            ERR-INSUFFICIENT-BALANCE
        )
        (asserts! (> duration u0) ERR-INVALID-PARAMS)
        (try! (stx-transfer? session-cost student (as-contract tx-sender)))
        (map-set sessions session-id {
            student: student,
            mentor: mentor,
            skill: skill,
            status: "scheduled",
            scheduled-time: scheduled-time,
            duration: duration,
            fee: session-cost,
            created-at: stacks-block-height,
        })
        (var-set next-session-id (+ session-id u1))
        (ok session-id)
    )
)

(define-public (complete-session (session-id uint))
    (let ((session (unwrap! (map-get? sessions session-id) ERR-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts!
            (or (is-eq tx-sender (get student session)) (is-eq tx-sender (get mentor session)))
            ERR-UNAUTHORIZED
        )
        (asserts! (is-eq (get status session) "scheduled") ERR-INVALID-PARAMS)
        (try! (as-contract (stx-transfer? (get fee session) tx-sender (get mentor session))))
        (begin
            (map-set sessions session-id (merge session { status: "completed" }))
            (unwrap-panic (update-session-counts (get student session) (get mentor session)))
            (ok true)
        )
    )
)

(define-public (cancel-session (session-id uint))
    (let ((session (unwrap! (map-get? sessions session-id) ERR-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts!
            (or (is-eq tx-sender (get student session)) (is-eq tx-sender (get mentor session)))
            ERR-UNAUTHORIZED
        )
        (asserts! (is-eq (get status session) "scheduled") ERR-INVALID-PARAMS)
        (try! (as-contract (stx-transfer? (get fee session) tx-sender (get student session))))
        (map-set sessions session-id (merge session { status: "cancelled" }))
        (ok true)
    )
)

(define-public (submit-review
        (session-id uint)
        (rating uint)
        (comment (string-ascii 200))
    )
    (let ((session (unwrap! (map-get? sessions session-id) ERR-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts!
            (or (is-eq tx-sender (get student session)) (is-eq tx-sender (get mentor session)))
            ERR-UNAUTHORIZED
        )
        (asserts! (is-eq (get status session) "completed") ERR-INVALID-PARAMS)
        (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-PARAMS)
        (asserts! (is-none (map-get? session-reviews session-id))
            ERR-ALREADY-EXISTS
        )
        (begin
            (map-set session-reviews session-id {
                reviewer: tx-sender,
                rating: rating,
                comment: comment,
                created-at: stacks-block-height,
            })
            (unwrap-panic (update-user-rating session rating))
            (ok true)
        )
    )
)

(define-public (update-session-counts
        (student principal)
        (mentor principal)
    )
    (let (
            (student-profile (unwrap-panic (map-get? student-profiles student)))
            (mentor-profile (unwrap-panic (map-get? mentor-profiles mentor)))
        )
        (begin
            (map-set student-profiles student
                (merge student-profile { total-sessions: (+ (get total-sessions student-profile) u1) })
            )
            (map-set mentor-profiles mentor
                (merge mentor-profile { total-sessions: (+ (get total-sessions mentor-profile) u1) })
            )
            (ok true)
        )
    )
)

(define-public (update-user-rating
        (session {
            student: principal,
            mentor: principal,
            skill: (string-ascii 30),
            status: (string-ascii 20),
            scheduled-time: uint,
            duration: uint,
            fee: uint,
            created-at: uint,
        })
        (rating uint)
    )
    (let ((reviewer tx-sender))
        (if (is-eq reviewer (get student session))
            (update-mentor-rating (get mentor session) rating)
            (update-student-rating (get student session) rating)
        )
    )
)

(define-public (update-mentor-rating
        (mentor principal)
        (new-rating uint)
    )
    (match (map-get? mentor-profiles mentor)
        profile (let (
                (current-rating (get rating profile))
                (total-sessions (get total-sessions profile))
                (updated-rating (if (is-eq current-rating u0)
                    new-rating
                    (/ (+ (* current-rating total-sessions) new-rating)
                        (+ total-sessions u1)
                    )
                ))
            )
            (begin
                (map-set mentor-profiles mentor
                    (merge profile { rating: updated-rating })
                )
                (ok true)
            )
        )
        ERR-NOT-FOUND
    )
)

(define-public (update-student-rating
        (student principal)
        (new-rating uint)
    )
    (match (map-get? student-profiles student)
        profile (let (
                (current-rating (get rating profile))
                (total-sessions (get total-sessions profile))
                (updated-rating (if (is-eq current-rating u0)
                    new-rating
                    (/ (+ (* current-rating total-sessions) new-rating)
                        (+ total-sessions u1)
                    )
                ))
            )
            (begin
                (map-set student-profiles student
                    (merge profile { rating: updated-rating })
                )
                (ok true)
            )
        )
        ERR-NOT-FOUND
    )
)

(define-public (set-contract-active (active bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set contract-active active)
        (ok true)
    )
)

(define-public (set-session-fee (fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set session-fee fee)
        (ok true)
    )
)

(define-public (withdraw-fees (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
        (ok true)
    )
)

(define-public (apply-for-verification)
    (let ((mentor tx-sender))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? mentor-profiles mentor)) ERR-NOT-FOUND)
        (asserts! (is-mentor-eligible-for-verification mentor) ERR-NOT-ELIGIBLE)
        (match (map-get? mentor-profiles mentor)
            profile (begin
                (map-set mentor-profiles mentor
                    (merge profile {
                        verified: true,
                        verification-date: stacks-block-height,
                    })
                )
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)

(define-public (revoke-verification (mentor principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? mentor-profiles mentor)) ERR-NOT-FOUND)
        (match (map-get? mentor-profiles mentor)
            profile (begin
                (map-set mentor-profiles mentor
                    (merge profile {
                        verified: false,
                        verification-date: u0,
                    })
                )
                (ok true)
            )
            ERR-NOT-FOUND
        )
    )
)

(define-public (set-verification-thresholds
        (rating-threshold uint)
        (sessions-threshold uint)
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (and (>= rating-threshold u1) (<= rating-threshold u5))
            ERR-INVALID-PARAMS
        )
        (asserts! (> sessions-threshold u0) ERR-INVALID-PARAMS)
        (var-set verification-threshold-rating rating-threshold)
        (var-set verification-threshold-sessions sessions-threshold)
        (ok true)
    )
)

;; Messaging System Functions

(define-private (is-registered-user (user principal))
    (or
        (is-some (map-get? student-profiles user))
        (is-some (map-get? mentor-profiles user))
    )
)

(define-private (is-thread-participant (thread-id uint) (user principal))
    (match (map-get? message-threads { thread-id: thread-id })
        thread (or
            (is-eq user (get participant-1 thread))
            (is-eq user (get participant-2 thread))
        )
        false
    )
)

(define-private (get-or-create-thread
        (sender principal)
        (recipient principal)
    )
    (let (
            (existing-thread (get-user-thread sender recipient))
            (thread-id (var-get thread-id-nonce))
        )
        (if (is-some existing-thread)
            (unwrap-panic existing-thread)
            (begin
                (map-set message-threads { thread-id: thread-id } {
                    participant-1: sender,
                    participant-2: recipient,
                    created-at: stacks-block-height,
                    last-message-at: stacks-block-height,
                    message-count: u0,
                })
                (map-set user-thread-mapping 
                    { user-1: sender, user-2: recipient } 
                    { thread-id: thread-id }
                )
                (var-set thread-id-nonce (+ thread-id u1))
                { thread-id: thread-id }
            )
        )
    )
)

(define-public (send-message
        (recipient principal)
        (content (string-utf8 500))
    )
    (let (
            (sender tx-sender)
            (message-id (var-get message-id-nonce))
        )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-registered-user sender) ERR-UNAUTHORIZED)
        (asserts! (is-registered-user recipient) ERR-NOT-FOUND)
        (asserts! (not (is-eq sender recipient)) ERR-INVALID-PARAMS)
        (asserts! (> (len content) u0) ERR-INVALID-MESSAGE-CONTENT)
        (asserts! (<= (len content) u500) ERR-MESSAGE-TOO-LONG)
        
        (let ((thread-info (get-or-create-thread sender recipient)))
            (let ((thread-id (get thread-id thread-info)))
                (map-set messages { message-id: message-id } {
                    thread-id: thread-id,
                    sender: sender,
                    content: content,
                    sent-at: stacks-block-height,
                    is-read: false,
                })
                
                (match (map-get? message-threads { thread-id: thread-id })
                    thread (map-set message-threads { thread-id: thread-id }
                        (merge thread {
                            last-message-at: stacks-block-height,
                            message-count: (+ (get message-count thread) u1),
                        })
                    )
                    false
                )
                
                (var-set message-id-nonce (+ message-id u1))
                (ok message-id)
            )
        )
    )
)

(define-public (mark-message-as-read (message-id uint))
    (let ((message (unwrap! (map-get? messages { message-id: message-id }) ERR-MESSAGE-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-thread-participant (get thread-id message) tx-sender)
            ERR-UNAUTHORIZED-MESSAGE-ACCESS
        )
        (ok (map-set messages { message-id: message-id }
            (merge message { is-read: true })
        ))
    )
)

(define-read-only (get-thread-messages
        (thread-id uint)
        (limit uint)
        (offset uint)
    )
    (begin
        (asserts! (is-thread-participant thread-id tx-sender) ERR-UNAUTHORIZED-MESSAGE-ACCESS)
        (ok {
            thread-id: thread-id,
            limit: limit,
            offset: offset,
            note: "Messages available through individual message queries"
        })
    )
)

(define-read-only (get-user-threads (user principal))
    (begin
        (asserts! (is-eq tx-sender user) ERR-UNAUTHORIZED)
        (ok {
            user: user,
            note: "Thread list available through individual thread queries"
        })
    )
)

(define-read-only (count-unread-messages-in-thread
        (thread-id uint)
        (user principal)
    )
    (begin
        (asserts! (is-thread-participant thread-id user) ERR-UNAUTHORIZED-MESSAGE-ACCESS)
        (ok {
            thread-id: thread-id,
            user: user,
            note: "Unread count available through message iteration"
        })
    )
)
