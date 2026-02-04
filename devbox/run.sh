#!/bin/bash

get_variable() {
    local var_name=$1
    local prompt_message=$2
    local var_value

    # Check if the environment variable is set
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_message" var_value
    else
        var_value="${!var_name}"
    fi

    echo "$var_value"  # Return the value
}

# Assigning variables
REMOTE_HOST=$(get_variable "REMOTE_HOST" "Please enter the remote host (IP/hostname): ")
REMOTE_USER=$(get_variable "REMOTE_USER" "Please enter your username for the remote host: ")
PEM_PATH=$(get_variable "PEM_PATH" "Please enter the path to your PEM file: ")

# Print confirmation
echo "Configuration Complete:"
echo "REMOTE_HOST: $REMOTE_HOST"
echo "REMOTE_USER: $REMOTE_USER"
echo "PEM_PATH: $PEM_PATH"

# Confirmation prompt
read -p "Do you want to proceed with these settings? (yes/no): " confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo "Exiting without proceeding."
    exit 1
fi

scp -i $PEM_PATH \
    amazon-linux-setup.sh \
    $REMOTE_USER@$REMOTE_HOST:/home/ec2-user/setup.sh
if [ -f ~/.ssh/id_rsa ]; then
    scp -i $PEM_PATH \
        ~/.ssh/id_rsa \
        $REMOTE_USER@$REMOTE_HOST:/home/ec2-user/.ssh/id_rsa
fi
if [ -f ~/.ssh/id_ed25519 ]; then
    scp -i $PEM_PATH \
        ~/.ssh/id_ed25519 \
        $REMOTE_USER@$REMOTE_HOST:/home/ec2-user/.ssh/id_ed25519
fi
ssh -i $PEM_PATH \
    ${REMOTE_USER}@${REMOTE_HOST} \
    "chmod +x setup.sh && ./setup.sh"
