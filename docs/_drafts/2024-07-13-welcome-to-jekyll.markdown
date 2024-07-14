---
layout: post
title:  "A failed attempt at improving Fujisaki-Okamoto transformation"
date:   2024-07-14 00:09:19 -0400
categories: cryptography
---

Recently I've been working on a generic construction that builds secure key encapsulation mechanism from cryptographic primitives with lesser security. While the initial idea sounded promising, after two months' work I found serious flaws in the design with no straightforward fix. It sucks that the idea ultimately did not pan out, but on the bright side it is still a valuable lesson in how hard it is to make sound cryptography.

# Some preliminaries
One of the main goals of cryptography is **confidentiality**, which means that when two parties communicate over an insecure channel, malicious third parties who can listen in (passive attack) and interfere (active attack) with this insecure channel still cannot learn any significant amount of information. In modern online protocols, this is usually achieved through a combination of two techniques:

1. A **key encapsulation mechanism (KEM)**, which allows two parties to establish a shared secret (also called a session key) over an insecure channel.
2. A **data encapsulation mechanism (DEM)**, which allows two parties who already have a shared secret to communicate securely over an insecure channel.

Data encapsulation mechanism seems to be a solved problem. **AES256-GCM** and **ChaCha20-Poly1305** have seen widespread use, have decades of research to back up their security claims, and are readily available for almost any platform and any programming language. Cryptographers also have strong confidence in their ability to resistant quantum attacks (when using 256-bit keys), though there is no definitive proof of such claims.

Key encapsulation mechanism on the other hand, remains an open question. The most popular method for establishing a session key is the Diffie-Hellman key exchange. Let $$G$$ be some group, $$g$$ be some non-zero element in the group. The two parties randomly generate some positive integers $$x,y$$ as their respective secret key, compute $$g^x, g^y$$ as their respective public keys. The two parties then exchange their public keys and compute the session key as $$g^{xy} = (g^x)^y = (g^y)^x$$.

In practice, $$G$$ is either a prime field (see [RFC7919](https://www.rfc-editor.org/rfc/rfc7919.html) for details) or a group of points on an elliptic curve (see [RFC7748](https://datatracker.ietf.org/doc/html/rfc7748) for details). Unfortunately, both setups can be efficiently broken with a sufficiently large quantum computer running Shor's algorithm. In fact, almost all modern public-key cryptography deployed on the Internet today will be broken due to the algebraic structure that a quanutm computer is particularly well-suited to exploit. Since power adversaries can intercept encrypted communication today and decrypt them later when quantum computers becomes sufficiently power, there is an urgent need to quickly migrate today's cryptography to something that is quantum resistant.

# The road to secure communication is littered with metaphorical (and physical) corposes
(Need to write an introduction?)

We've seen remarkable progress toward 

[Kyber timing variability](https://groups.google.com/a/list.nist.gov/g/pqc-forum/c/hqbtIGFKIpU)