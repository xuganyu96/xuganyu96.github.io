---
layout: post
title:  "Zero to embedded PQ-TLS part 3: the TLS protocol"
date: 2025-07-15 14:28:37 -0400
categories: cryptography
---

# TLS 1.3 protocol overview
The TLS 1.3 protocol consists mainly of two sub-protocols.
After establishing a TCP connection, client and server first go through the handshake protocol.
During the handshake, the two parties negotiate protocol versions, establish cryptographic parameters and keys, and optionally authenticate each other by exchanging messages.
If the handshake succeeds, then the two parties move on to exchange application-layer data, encrypted under keys derived from the handshake.
If the handshake fails, then the session is terminated, and the two parties need to restart the handshake.
With TLS 1.3, the handshake protocol itself can be cleanly divided into two phases.

The first is key exchange, which includes `ClientHello` and `ServerHello`.
The two hello messages are sent as plaintext because there is nothing to encrypt it with.
However, after exchanging these two messages, client and server obtain a shared secret and use it to derive a pair of symmetric keys.
These keys are called client/server handshake traffic keys (CHTS/SHTS) and they are used to encrypt all subsequent messages in the handshake.
We will discuss more about synchronizing symmetric keys [later](#tls-13-key-schedule).

The second phase is authentication, which includes the following messages:
- `Certificate`: Server presents a cryptographic public key that is bound to some identity via [public key infrastructure](#public-key-infrastructure).
- `CertificateVerify`: Server proves its identity by demonstrating possession of the corresponding private key.
- `Finished`: server and client (in this order) confirm the integrity of the entire handshake to each other.

Each party will update the [key schedule](#tls-13-key-schedule) to derive another pair of symmetric keys, which are used to encrypt application layer data (CATS/SATS).
Each party can start sending encrypted application data after sending `Finished`.
This means that server can start sending encrypted application data with the first batch of messages (including `ServerHello`, `Certificate`, `CertificateVerify`, and server's `Finished`).
Client can start sending encrypted application data after one round trip (1-RTT).

## Public key infrastructure

## TLS 1.3 key schedule