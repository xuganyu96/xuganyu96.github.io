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
EC2_REMOTE_HOST=$(get_variable "EC2_REMOTE_HOST" "Please enter the remote host (IP/hostname): ")
EC2_REMOTE_USER=$(get_variable "EC2_REMOTE_USER" "Please enter your username for the remote host: ")
EC2_PEM_PATH=$(get_variable "EC2_PEM_PATH" "Please enter the path to your PEM file: ")

# Print confirmation
echo "EC2_REMOTE_HOST: ${EC2_REMOTE_HOST}"
echo "EC2_REMOTE_USER: ${EC2_REMOTE_USER}"
echo "EC2_PEM_PATH: ${EC2_PEM_PATH}"

# Confirmation prompt
read -p "Do you want to proceed with these settings? (yes/no): " confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo "Exiting without proceeding."
    exit 1
fi

# TODO: figure out how to do SSH agent forwarding
# TODO: figure out how to disable strict host name checking
scp -i ${EC2_PEM_PATH} \
    amazon-linux-setup.sh \
    ${EC2_REMOTE_USER}@${EC2_REMOTE_HOST}:/home/${EC2_REMOTE_USER}/setup.sh
# if [ -f ~/.ssh/id_rsa ]; then
#     scp -i ${EC2_PEM_PATH} \
#         ~/.ssh/id_rsa \
#         ${EC2_REMOTE_USER}@${EC2_REMOTE_HOST}:/home/${EC2_REMOTE_USER}/.ssh/id_rsa
# fi
if [ -f ~/.ssh/id_ed25519 ]; then
    scp -i ${EC2_PEM_PATH} \
        ~/.ssh/id_ed25519 \
        ${EC2_REMOTE_USER}@${EC2_REMOTE_HOST}:/home/${EC2_REMOTE_USER}/.ssh/id_ed25519
fi
ssh -i ${EC2_PEM_PATH} \
    ${EC2_REMOTE_USER}@${EC2_REMOTE_HOST} \
    "chmod +x setup.sh && ./setup.sh"
ssh -i ${EC2_PEM_PATH} -L 8080:${EC2_REMOTE_HOST}:8080 ${EC2_REMOTE_USER}@${EC2_REMOTE_HOST}

# NOTE: to copy a git repository
# rsync -azhr \
#   --info=progress2 \
#   --exclude ".venv/" \
#   -e "ssh -i ${EC2_PEM_PATH}" \
#   <src> ${EC2_REMOTE_USER}@${EC2_REMOTE_HOST}:<path>
