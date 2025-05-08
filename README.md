# **Chatty**

# End-to-End Encryption Overview

This system uses modern cryptography standards to secure both 1-to-1 and group (1-to-many) messages. It ensures that **only the intended recipients** can read the messages, keeping them safe from third parties.

---

## 🔒 1-to-1 Encryption

### 1. X25519 (Asymmetric Algorithm)

* Based on **Elliptic Curve Diffie-Hellman (ECDH)**.
* Purpose:

  * Generates **public/private key pairs** for users.
  * Used for secure **key exchange**.
* Advantages: Fast, secure, and preferred over older algorithms like RSA.

> Used by WhatsApp, Signal, and iMessage.

---

### 2. ECDH Key Exchange

* Combines **your private key** and **recipient’s public key** to derive a **shared secret**.
* This shared secret becomes the **session key** for symmetric encryption.
* It ensures that **only the two parties** involved can compute the key — nobody else can intercept it.

---

### 3. AES-GCM (Symmetric Encryption)

* **AES** (Advanced Encryption Standard): Encrypts the message content.
* **GCM** (Galois/Counter Mode):

  * Provides both **encryption** and **authentication**.
* Uses **AES-256** (256-bit keys) for strong security.

> Note: AES-GCM is currently the best practice for real-time encrypted messaging.

---

### 4. Message Authentication Code (MAC)

* Automatically bundled with AES-GCM.
* Ensures:

  * The message hasn’t been tampered with.
  * The recipient can verify authenticity.
* In code, this is the `mac` value that accompanies the ciphertext.

---

### Encrypted Message Format (1-to-1)

```json
{
  "sender_id": "iJuSlj5RwdfWoO6WBKcZU9gHwRz2",
  "recipient_id": "qgIdyBHtLZQeoNmVLCxihAPr77M2",
  "ciphertext": "...",
  "nonce": "...",
  "mac": "...",
  "timestamp": "...",
  "read": false
}
```

---

## 1-to-Many (Group) Encryption

### Per-Message Symmetric Key + Per-User Encrypted Keys

#### Step 1: Generate a Random Key (Per Message)

* For each group message, generate a fresh random **symmetric key** (`messageKey`).
* This key encrypts **only this one message**.

#### Step 2: Encrypt the Message Content

* Encrypt the actual message (e.g., *"Hello group!"*) using `messageKey` with **AES-GCM**.

#### Step 3: Encrypt the Message Key for Each Group Member

For every group member:

* Derive a shared key using ECDH.
* Encrypt the `messageKey` using that member’s key.
* Store the result in the `encryptedKeys` map.

---

###  How Group Members Decrypt Messages

1. Retrieve their encrypted message key from `encryptedKeys`.
2. Decrypt that key using their own shared key.
3. Use the decrypted `messageKey` to decrypt the actual message content.

---

###  Encrypted Message Format (Group)

```json
{
  "groupId": "uAZKrVzCTvu1zyJ9prAq",
  "ciphertext": "base64-encoded-encrypted-message",
  "nonce": "base64-encoded-nonce",
  "mac": "base64-encoded-mac",
  
  "encryptedKeys": {
    "user1@example.com": {
      "key": "encrypted-key-for-user1",
      "nonce": "nonce1",
      "mac": "mac1"
    },
    "user2@example.com": {
      "key": "encrypted-key-for-user2",
      "nonce": "nonce2",
      "mac": "mac2"
    }
  },

  "senderId": "VrumwPkTXwd40f1DVfFqQ8XLTfn2",
  "senderImageUrl": "https://...",
  "senderName": "sabrine",
  "timestamp": "May 8, 2025 at 10:50"
}
```

---

##  Why This Design is Secure

* **ECDH + X25519**: Ensures that session keys are only derivable by the intended sender and recipient(s).
* **AES-GCM**: Encrypts data while also verifying its integrity.
* **Per-user key wrapping** (for groups): Makes sure that only group members can access the message key.
