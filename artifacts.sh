#!/bin/bash

set -euo pipefail

mkdir -p artifacts
./main.py rsakeygen --pubkey artifacts/pubkey.pem --privkey artifacts/privkey.pem
./main.py encrypt CodingExercise.JPG artifacts/pubkey.pem artifacts/ciphertext.txt
./main.py decrypt artifacts/ciphertext.txt artifacts/privkey.pem artifacts/decryption.jpg

lhs="$(./main.py sha256sum CodingExercise.JPG)"
rhs="$(./main.py sha256sum artifacts/decryption.jpg)"

if [ "$lhs" = "$rhs" ]; then
    echo "Ok."
    exit 0
else
    echo "Decryption failed."
    exit 1
fi
