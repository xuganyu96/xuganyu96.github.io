# Keyless EC2 SSH 
When checking out an EC2 instance (referred to as "remote server" from this point on) from scratch, the user will be instructed to create a private-key (often a PEM file) or select a private-key that the user already has. Subsequently, the SSH process involves specifying the private-key file in an `-i` flag, which creates inconvenience when there are more than one developer trying to remotely access the EC2 instance. 

Without using a third-party key manager like Userify, I would like to build a solution that automates a process in which the remote server runs a shell script that pulls a number of id_rsa.pub public keys from an S3 bucket and add them to `~/.ssh/authorized_keys` so that all users who have put their public keys onto the S3 bucket can SSH into the remote server without needing the priavte-key PEM file.

Here are the components that need to be in place:
* An S3 bucket that holds public key files
* An IAM role given to the remote server for reading from S3 bucket
* A shell script for iterating through the public key files and adding them to `authorized_keys`

## Create a bucket
Begin by creating an S3 bucket, which I will refer to as the `ssh-public-key` bucket, then from the console, upload the public key file `id_rsa.pub` to file key `some_username/public_key.pub`.

## Create an IAM role that is given read access to the SSH public key bucket
Refer to [this guide](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-access-s3-bucket/) for the full instruction:
* Create an IAM role that has full access to S3 bucket
* Attach the IAM role to the remote server
* Review the S3 bucket's policies such that the IAM role just created is not blocked
* Install aws-cli on the remote server and try `aws s3 ls s3://ssh-public-keys/username/key.pub`

## Develop and insert the script
Now we are going to develop the shell script for reading each of the public keys and adding them to `~/.ssh/authorized_keys`
```bash
#!/bin/bash
apt-get update
apt-get install -y awscli
aws s3 sync s3://bruce-ssh-public-keys /tmp/temporary_keys
cd /tmp/temporary_keys


for username in *
do   
  adduser --disabled-password --gecos "" $username
  echo "$username:password" | chpasswd
  usermod -aG sudo $username
  mkdir /home/$username/.ssh
  cat /tmp/temporary_keys/$username/*.pub >> /home/$username/.ssh/authorized_keys
done
```

Now when launching a new EC2 instance, at **Configure Instance Details**, select the S3 full access IAM role and copy/paste the script above to **User Data**.