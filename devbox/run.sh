#!/bin/bash

REMOTE_HOST=$1

if [[ -z "${REMOTE_HOST}" ]]; then
    echo ">>> please enter the remote host"
    read USER_INPUT
    REMOTE_HOST=${USER_INPUT}
fi

echo -n "Setting up ${REMOTE_HOST}? (Y/N)?"
read USER_INPUT
if [[ $USER_INPUT != "Y" ]]; then
    echo "Abort setup"
    exit 0
fi

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
    ssh -i $PEM_PATH ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod +x ~/setup.sh && sudo ~/setup.sh"
}
ssh -i $PEM_PATH ${REMOTE_USER}@${REMOTE_HOST}
