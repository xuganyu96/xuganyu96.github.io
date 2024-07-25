#!/bin/bash

REMOTE_HOST=$1

print_info() {
    echo -e "\033[1;34m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m$1\033[0m"
}

print_warning() {
    echo -e "\033[1m\033[91m$1\033[0m"
}

time {
    scp -i $PEM_PATH \
        ./amazon-linux-setup.sh \
        ${REMOTE_USER}@${REMOTE_HOST}:/home/${REMOTE_USER}/setup.sh
    scp -i $PEM_PATH \
        ~/.ssh/id_rsa \
        ${REMOTE_USER}@${REMOTE_HOST}:/home/${REMOTE_USER}/.ssh/id_rsa
    scp -i $PEM_PATH \
        ~/.ssh/id_rsa.pub \
        ${REMOTE_USER}@${REMOTE_HOST}:/home/${REMOTE_USER}/.ssh/id_rsa.pub
}
print_info "source setup.sh && setup_all"
ssh -i $PEM_PATH ${REMOTE_USER}@${REMOTE_HOST}
