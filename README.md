# 🎓 Mentor-Matching Smart Contract

A decentralized mentor-matching platform built on Stacks blockchain that connects students with mentors based on skills and expertise.

## 🚀 Features

- 👩‍🎓 **Student Profiles**: Create profiles with skills you want to learn and budget
- 👨‍🏫 **Mentor Profiles**: Create profiles with skills you can teach and rates
- 🤝 **Automated Matching**: Match students to mentors based on skill compatibility
- 📅 **Session Management**: Schedule, complete, and cancel mentoring sessions
- ⭐ **Rating System**: Rate mentors and students after sessions
- 💰 **Secure Payments**: Automatic payment handling with escrow functionality
- 🕐 **Availability Tracking**: Mentors can set their available time slots

## 📋 Contract Functions

### Student Functions

#### `create-student-profile`
Create a new student profile with learning goals and budget.

```clarity
(contract-call? .mentor-matching create-student-profile 
  "John Doe" 
  (list "JavaScript" "React" "Node.js") 
  "Beginner" 
  u500000)
```

#### `update-student-profile`
Update your existing student profile.

```clarity
(contract-call? .mentor-matching update-student-profile 
  "John Doe" 
  (list "JavaScript" "React") 
  "Intermediate" 
  u750000)
```

### Mentor Functions

#### `create-mentor-profile`
Create a new mentor profile with skills and hourly rate.

```clarity
(contract-call? .mentor-matching create-mentor-profile 
  "Jane Smith" 
  (list "JavaScript" "React" "Node.js" "Python") 
  u5 
  u100000)
```

#### `update-mentor-profile`
Update your existing mentor profile.

```clarity
(contract-call? .mentor-matching update-mentor-profile 
  "Jane Smith" 
  (list "JavaScript" "React" "Python" "TypeScript") 
  u7 
  u150000)
```

#### `toggle-mentor-availability`
Toggle your availability status (active/inactive).

```clarity
(contract-call? .mentor-matching toggle-mentor-availability)
```

#### `set-mentor-availability`
Set your available time slots and timezone.

```clarity
(contract-call? .mentor-matching set-mentor-availability 
  (list u1640995200 u1641001200 u1641007200) 
  "UTC")
```

### Session Functions

#### `create-session`
Book a mentoring session with a mentor.

```clarity
(contract-call? .mentor-matching create-session 
  'SP1MENTOR123... 
  "JavaScript" 
  u1640995200 
  u2)
```

#### `complete-session`
Mark a session as completed (can be called by student or mentor).

```clarity
(contract-call? .mentor-matching complete-session u1)
```

#### `cancel-session`
Cancel a scheduled session and refund the student.

```clarity
(contract-call? .mentor-matching cancel-session u1)
```

#### `submit-review`
Submit a review and rating after a completed session.

```clarity
(contract-call? .mentor-matching submit-review 
  u1 
  u5 
  "Great mentor! Very helpful and patient.")
```

### Read Functions

#### `get-student-profile`
Get student profile information.

```clarity
(contract-call? .mentor-matching get-student-profile 'SP1STUDENT123...)
```

#### `get-mentor-profile`
Get mentor profile information.

```clarity
(contract-call? .mentor-matching get-mentor-profile 'SP1MENTOR123...)
```

#### `get-session`
Get session details by ID.

```clarity
(contract-call? .mentor-matching get-session u1)
```

#### `get-session-review`
Get review for a specific session.

```clarity
(contract-call? .mentor-matching get-session-review u1)
```

## 🔧 Setup and Deployment

### Prerequisites

- [Clarinet](https://docs.hiro.co/stacks/clarinet/quickstart)
- [Node.js](https://nodejs.org/) (for testing)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mentor-matching-smart-contract
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

### Deployment

1. Deploy to testnet:
```bash
clarinet deploy --testnet
```

2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## 🎯 Usage Flow

1. **Setup**: 
   - Students create profiles with skills they want to learn
   - Mentors create profiles with skills they can teach

2. **Matching**:
   - Students find mentors with matching skills
   - Check mentor availability and rates

3. **Booking**:
   - Students book sessions with mentors
   - Payment is held in escrow

4. **Session**:
   - Conduct mentoring session
   - Complete session to release payment

5. **Review**:
   - Both parties can leave reviews and ratings

## 💡 Example Workflow

```clarity
;; 1. Student creates profile
(contract-call? .mentor-matching create-student-profile 
  "Alice" 
  (list "Solidity" "DeFi") 
  "Beginner" 
  u1000000)

;; 2. Mentor creates profile
(contract-call? .mentor-matching create-mentor-profile 
  "Bob" 
  (list "Solidity" "DeFi" "Smart Contracts") 
  u3 
  u200000)

;; 3. Student books session
(contract-call? .mentor-matching create-session 
  'SP1MENTOR123... 
  "Solidity" 
  u1640995200 
  u2)

;; 4. Complete session
(contract-call? .mentor-matching complete-session u0)

;; 5. Leave review
(contract-call? .mentor-matching submit-review 
  u0 
  u5 
  "Excellent mentor!")
```

## 🔒 Security Features

- 💸 **Escrow System**: Payments held securely until session completion
- 👤 **Identity Verification**: Profile ownership validation
- 🛡️ **Access Control**: Only session participants can complete/cancel
- 📊 **Rating System**: Prevents spam and ensures quality

## 📈 Contract State

The contract maintains several data maps:
- `student-profiles`: Student information and preferences
- `mentor-profiles`: Mentor information and skills
- `sessions`: Session details and status
- `session-reviews`: Reviews and ratings
- `mentor-availability`: Mentor time slots
- `skill-matches`: Cached skill compatibility scores

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 🆘 Support

For questions or support, please open an issue in the repository.
