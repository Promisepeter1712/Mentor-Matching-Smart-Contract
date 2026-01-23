import { describe, expect, it } from "vitest";
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const student1 = accounts.get("wallet_1")!;
const student2 = accounts.get("wallet_2")!;
const mentor1 = accounts.get("wallet_3")!;
const mentor2 = accounts.get("wallet_4")!;
const unregistered = accounts.get("wallet_5")!;

const contractName = "Mentor-Matching-Smart-Contract";

// Helper function to create student profile
function createStudentProfile(student: string, name: string) {
  const { result } = simnet.callPublicFn(
    contractName,
    "create-student-profile",
    [
      Cl.stringAscii(name),
      Cl.list([Cl.stringAscii("JavaScript"), Cl.stringAscii("Python")]),
      Cl.stringAscii("beginner"),
      Cl.uint(500000),
    ],
    student
  );
  return result;
}

// Helper function to create mentor profile  
function createMentorProfile(mentor: string, name: string) {
  const { result } = simnet.callPublicFn(
    contractName,
    "create-mentor-profile",
    [
      Cl.stringAscii(name),
      Cl.list([Cl.stringAscii("JavaScript"), Cl.stringAscii("Python")]),
      Cl.uint(2),
      Cl.uint(250000),
    ],
    mentor
  );
  return result;
}

describe("Messaging System", () => {
  it("should allow students to send messages to mentors", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Send message
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Hello, I need help with JavaScript")
      ],
      student1
    );

    expect(result).toBeOk(expect.anything());
  });

  it("should allow mentors to send messages to students", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Send message
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(student1),
        Cl.stringUtf8("Hi Alice, I can help you!")
      ],
      mentor1
    );

    expect(result).toBeOk(expect.anything());
  });

  it("should reject messages from unregistered users", () => {
    // Setup only mentor profile
    createMentorProfile(mentor1, "Bob Mentor");

    // Unregistered user tries to send message
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Unauthorized message")
      ],
      unregistered
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should reject messages to unregistered users", () => {
    // Setup only student profile
    createStudentProfile(student1, "Alice Student");

    // Try to send message to unregistered user
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(unregistered),
        Cl.stringUtf8("Message to unregistered")
      ],
      student1
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should reject empty messages", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Try to send empty message
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("")
      ],
      student1
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should reject messages that are too long", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Create message longer than 500 characters
    const longMessage = "a".repeat(501);
    
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8(longMessage)
      ],
      student1
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should prevent users from messaging themselves", () => {
    // Setup profile
    createStudentProfile(student1, "Alice Student");

    // Try to send message to self
    const { result } = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(student1),
        Cl.stringUtf8("Message to myself")
      ],
      student1
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should allow marking messages as read by participants", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Send message
    const sendResult = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Test message")
      ],
      student1
    );

    expect(sendResult.result).toBeOk(expect.anything());
    
    // Extract message ID
    const messageIdClarityValue = sendResult.result;
    const messageId = (messageIdClarityValue as any).value.value as bigint;

    // Mark as read by mentor
    const { result } = simnet.callPublicFn(
      contractName,
      "mark-message-as-read",
      [Cl.uint(messageId)],
      mentor1
    );

    expect(result).toBeOk(expect.anything());
  });

  it("should prevent non-participants from marking messages as read", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");
    createStudentProfile(student2, "Charlie Student");

    // Send message between student1 and mentor1
    const sendResult = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Private message")
      ],
      student1
    );

    expect(sendResult.result).toBeOk(expect.anything());
    
    const messageId = (sendResult.result as any).value.value as bigint;

    // student2 should not be able to mark the message as read
    const { result } = simnet.callPublicFn(
      contractName,
      "mark-message-as-read",
      [Cl.uint(messageId)],
      student2
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should provide message details to anyone", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Send message
    const sendResult = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Test message")
      ],
      student1
    );

    expect(sendResult.result).toBeOk(expect.anything());
    
    const messageId = (sendResult.result as any).value.value as bigint;

    // Check message details
    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-message-details",
      [Cl.uint(messageId)],
      student1
    );

    expect(result).toBeSome(expect.anything());
  });

  it("should handle non-existent message requests gracefully", () => {
    const nonExistentMessageId = 99999;
    
    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-message-details",
      [Cl.uint(nonExistentMessageId)],
      student1
    );

    expect(result).toBeNone();
  });

  it("should handle non-existent thread requests gracefully", () => {
    const nonExistentThreadId = 99999;

    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-thread-details",
      [Cl.uint(nonExistentThreadId)],
      student1
    );

    expect(result).toBeNone();
  });

  it("should enforce thread participant access control", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");
    createStudentProfile(student2, "Charlie Student");

    // Create thread between student1 and mentor1
    const sendResult = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Private thread")
      ],
      student1
    );

    expect(sendResult.result).toBeOk(expect.anything());

    const threadId = 0; // First thread

    // student2 should not be able to access the thread
    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-thread-messages",
      [Cl.uint(threadId), Cl.uint(10), Cl.uint(0)],
      student2
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should prevent users from accessing other users' thread lists", () => {
    // Setup profiles
    createStudentProfile(student1, "Alice Student");
    createStudentProfile(student2, "Charlie Student");

    // student2 should not be able to access student1's threads
    const { result } = simnet.callReadOnlyFn(
      contractName,
      "get-user-threads",
      [Cl.principal(student1)],
      student2
    );

    expect(result).toBeErr(expect.anything());
  });

  it("should respect contract active state", () => {
    // Setup profiles first
    createStudentProfile(student1, "Alice Student");
    createMentorProfile(mentor1, "Bob Mentor");

    // Deactivate contract
    const deactivateResult = simnet.callPublicFn(
      contractName,
      "set-contract-active",
      [Cl.bool(false)],
      deployer
    );

    expect(deactivateResult.result).toBeOk(expect.anything());

    // Try to send message while contract is inactive
    const sendResult = simnet.callPublicFn(
      contractName,
      "send-message",
      [
        Cl.principal(mentor1),
        Cl.stringUtf8("Should fail")
      ],
      student1
    );

    expect(sendResult.result).toBeErr(expect.anything());

    // Reactivate contract
    const reactivateResult = simnet.callPublicFn(
      contractName,
      "set-contract-active",
      [Cl.bool(true)],
      deployer
    );

    expect(reactivateResult.result).toBeOk(expect.anything());
  });
});
