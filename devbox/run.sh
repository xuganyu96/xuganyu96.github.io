#!/bin/bash

REMOTE_HOST=$1

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
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  source setup.sh && setup_all"
ssh -i $PEM_PATH ${REMOTE_USER}@${REMOTE_HOST}
