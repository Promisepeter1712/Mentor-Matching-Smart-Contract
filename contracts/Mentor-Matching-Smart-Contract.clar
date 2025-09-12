(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-NOT-ELIGIBLE (err u403))

(define-data-var contract-active bool true)
(define-data-var session-fee uint u1000000)
(define-data-var next-session-id uint u0)
(define-data-var verification-threshold-rating uint u4)
(define-data-var verification-threshold-sessions uint u10)
(define-data-var next-program-id uint u0)

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

(define-map mentorship-programs
    uint
    {
        mentor: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        skill: (string-ascii 30),
        total-cost: uint,
        duration-weeks: uint,
        milestone-count: uint,
        active: bool,
        created-at: uint,
    }
)

(define-map program-milestones
    {
        program-id: uint,
        milestone-index: uint,
    }
    {
        title: (string-ascii 100),
        description: (string-ascii 300),
        payment-percentage: uint,
        estimated-weeks: uint,
        requirements: (string-ascii 200),
    }
)

(define-map program-enrollments
    {
        program-id: uint,
        student: principal,
    }
    {
        enrolled-at: uint,
        current-milestone: uint,
        total-paid: uint,
        status: (string-ascii 20),
        completed-milestones: (list 20 uint),
    }
)

(define-map milestone-submissions
    {
        program-id: uint,
        student: principal,
        milestone-index: uint,
    }
    {
        submission-text: (string-ascii 500),
        submitted-at: uint,
        reviewed: bool,
        approved: bool,
        mentor-feedback: (string-ascii 300),
        reviewed-at: uint,
    }
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

(define-read-only (get-mentorship-program (program-id uint))
    (map-get? mentorship-programs program-id)
)

(define-read-only (get-program-milestone
        (program-id uint)
        (milestone-index uint)
    )
    (map-get? program-milestones {
        program-id: program-id,
        milestone-index: milestone-index,
    })
)

(define-read-only (get-program-enrollment
        (program-id uint)
        (student principal)
    )
    (map-get? program-enrollments {
        program-id: program-id,
        student: student,
    })
)

(define-read-only (get-milestone-submission
        (program-id uint)
        (student principal)
        (milestone-index uint)
    )
    (map-get? milestone-submissions {
        program-id: program-id,
        student: student,
        milestone-index: milestone-index,
    })
)

(define-read-only (get-next-program-id)
    (var-get next-program-id)
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

(define-public (create-mentorship-program
        (title (string-ascii 100))
        (description (string-ascii 500))
        (skill (string-ascii 30))
        (total-cost uint)
        (duration-weeks uint)
        (milestone-count uint)
    )
    (let (
            (mentor tx-sender)
            (program-id (var-get next-program-id))
        )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? mentor-profiles mentor)) ERR-NOT-FOUND)
        (asserts! (> (len title) u0) ERR-INVALID-PARAMS)
        (asserts! (> total-cost u0) ERR-INVALID-PARAMS)
        (asserts! (> duration-weeks u0) ERR-INVALID-PARAMS)
        (asserts! (and (> milestone-count u0) (<= milestone-count u20))
            ERR-INVALID-PARAMS
        )
        (begin
            (map-set mentorship-programs program-id {
                mentor: mentor,
                title: title,
                description: description,
                skill: skill,
                total-cost: total-cost,
                duration-weeks: duration-weeks,
                milestone-count: milestone-count,
                active: true,
                created-at: stacks-block-height,
            })
            (var-set next-program-id (+ program-id u1))
            (ok program-id)
        )
    )
)

(define-public (set-program-milestone
        (program-id uint)
        (milestone-index uint)
        (title (string-ascii 100))
        (description (string-ascii 300))
        (payment-percentage uint)
        (estimated-weeks uint)
        (requirements (string-ascii 200))
    )
    (let ((program (unwrap! (map-get? mentorship-programs program-id) ERR-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-eq tx-sender (get mentor program)) ERR-UNAUTHORIZED)
        (asserts! (< milestone-index (get milestone-count program))
            ERR-INVALID-PARAMS
        )
        (asserts! (> (len title) u0) ERR-INVALID-PARAMS)
        (asserts! (and (> payment-percentage u0) (<= payment-percentage u100))
            ERR-INVALID-PARAMS
        )
        (asserts! (> estimated-weeks u0) ERR-INVALID-PARAMS)
        (ok (map-set program-milestones {
            program-id: program-id,
            milestone-index: milestone-index,
        } {
            title: title,
            description: description,
            payment-percentage: payment-percentage,
            estimated-weeks: estimated-weeks,
            requirements: requirements,
        }))
    )
)

(define-public (enroll-in-program (program-id uint))
    (let (
            (student tx-sender)
            (program (unwrap! (map-get? mentorship-programs program-id) ERR-NOT-FOUND))
        )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? student-profiles student)) ERR-NOT-FOUND)
        (asserts! (get active program) ERR-UNAUTHORIZED)
        (asserts!
            (is-none (map-get? program-enrollments {
                program-id: program-id,
                student: student,
            }))
            ERR-ALREADY-EXISTS
        )
        (try! (stx-transfer? (get total-cost program) student (as-contract tx-sender)))
        (ok (map-set program-enrollments {
            program-id: program-id,
            student: student,
        } {
            enrolled-at: stacks-block-height,
            current-milestone: u0,
            total-paid: u0,
            status: "active",
            completed-milestones: (list),
        }))
    )
)

(define-public (submit-milestone
        (program-id uint)
        (milestone-index uint)
        (submission-text (string-ascii 500))
    )
    (let (
            (student tx-sender)
            (enrollment (unwrap!
                (map-get? program-enrollments {
                    program-id: program-id,
                    student: student,
                })
                ERR-NOT-FOUND
            ))
        )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status enrollment) "active") ERR-UNAUTHORIZED)
        (asserts! (is-eq milestone-index (get current-milestone enrollment))
            ERR-INVALID-PARAMS
        )
        (asserts! (> (len submission-text) u0) ERR-INVALID-PARAMS)
        (ok (map-set milestone-submissions {
            program-id: program-id,
            student: student,
            milestone-index: milestone-index,
        } {
            submission-text: submission-text,
            submitted-at: stacks-block-height,
            reviewed: false,
            approved: false,
            mentor-feedback: "",
            reviewed-at: u0,
        }))
    )
)

(define-public (review-milestone
        (program-id uint)
        (student principal)
        (milestone-index uint)
        (approved bool)
        (feedback (string-ascii 300))
    )
    (let (
            (program (unwrap! (map-get? mentorship-programs program-id) ERR-NOT-FOUND))
            (submission (unwrap!
                (map-get? milestone-submissions {
                    program-id: program-id,
                    student: student,
                    milestone-index: milestone-index,
                })
                ERR-NOT-FOUND
            ))
            (enrollment (unwrap!
                (map-get? program-enrollments {
                    program-id: program-id,
                    student: student,
                })
                ERR-NOT-FOUND
            ))
            (milestone (unwrap!
                (map-get? program-milestones {
                    program-id: program-id,
                    milestone-index: milestone-index,
                })
                ERR-NOT-FOUND
            ))
        )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-eq tx-sender (get mentor program)) ERR-UNAUTHORIZED)
        (asserts! (not (get reviewed submission)) ERR-ALREADY-EXISTS)
        (begin
            (map-set milestone-submissions {
                program-id: program-id,
                student: student,
                milestone-index: milestone-index,
            }
                (merge submission {
                    reviewed: true,
                    approved: approved,
                    mentor-feedback: feedback,
                    reviewed-at: stacks-block-height,
                })
            )
            (if approved
                (complete-milestone program-id student milestone-index milestone
                    enrollment
                )
                (ok true)
            )
        )
    )
)

(define-private (complete-milestone
        (program-id uint)
        (student principal)
        (milestone-index uint)
        (milestone {
            title: (string-ascii 100),
            description: (string-ascii 300),
            payment-percentage: uint,
            estimated-weeks: uint,
            requirements: (string-ascii 200),
        })
        (enrollment {
            enrolled-at: uint,
            current-milestone: uint,
            total-paid: uint,
            status: (string-ascii 20),
            completed-milestones: (list 20 uint),
        })
    )
    (let (
            (program (unwrap-panic (map-get? mentorship-programs program-id)))
            (payment-amount (/ (* (get total-cost program) (get payment-percentage milestone))
                u100
            ))
            (new-total-paid (+ (get total-paid enrollment) payment-amount))
            (updated-completed-milestones (unwrap-panic (as-max-len?
                (append (get completed-milestones enrollment) milestone-index)
                u20
            )))
            (is-program-complete (is-eq (+ milestone-index u1) (get milestone-count program)))
        )
        (try! (as-contract (stx-transfer? payment-amount tx-sender (get mentor program))))
        (map-set program-enrollments {
            program-id: program-id,
            student: student,
        } {
            enrolled-at: (get enrolled-at enrollment),
            current-milestone: (if is-program-complete
                milestone-index
                (+ milestone-index u1)
            ),
            total-paid: new-total-paid,
            status: (if is-program-complete
                "completed"
                "active"
            ),
            completed-milestones: updated-completed-milestones,
        })
        (ok true)
    )
)

(define-public (toggle-program-status (program-id uint))
    (let ((program (unwrap! (map-get? mentorship-programs program-id) ERR-NOT-FOUND)))
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (is-eq tx-sender (get mentor program)) ERR-UNAUTHORIZED)
        (ok (map-set mentorship-programs program-id
            (merge program { active: (not (get active program)) })
        ))
    )
)
