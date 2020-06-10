# Static domain name for SSH 

## A static domain name through AWS Route 53 
My staging and production environments are each going to be hosted on an EC2 instance, which I want 
to be able to access by something like below:

```bash
#   SSH into production server
ssh production-ssh.bruce-learning-the-web.online
ssh staging-ssh.bruce-learning-the-web.online
```

In this case the task at hand is as follows:  
Given that I have purchased a domain name from GoDaddy, how can I spin up an EC2 instance and set it up such that when I want to SSH into the instance, I don't call the naked domain name like 
`ec2-35-162-21-39.us-west-2.compute.amazonaws.com` but instead call the purchased domain like 
scripted above.

The steps below assumes that the domain that I am going to purchase is called `bruce-learning-the-web.online`
### We begin with AWS Route 53 console
1. Go to `Hosted zones` tab, click `Create Hosted Zone`, then enter domain name. For now I will choose public hosted zone for the type of hosted zone. 
2. Click into the hosted zone that was just created, then click on `Create Record Set`; I wanted to route SSH traffic to my staging server (an EC2 instance) using the domain name that I purchased, therefore:
    * `ssh-staging.bruce-learning-the-web.online` for name
    * Choose `IPv4` for record type
    * Let `alias` and `TLS` remain to default value
    * Under `Value`, enter the `IPv4` address of the staging server, which you can find under the EC2 console
    * Routing policy will remain default 

### Configure GoDaddy 
* Go to the GoDaddy website and sign in; under `Domains`, click the three dots under the domain that I justed purchase, and click `manage DNS`. 
* Under `Nameservers`, enter the nameservers in `Hosted zones` in AWS Route 53 console# Things I want to set up

## A static domain name through AWS Route 53 
My staging and production environments are each going to be hosted on an EC2 instance, which I want 
to be able to access by something like below:

```bash
#   SSH into production server
ssh production-ssh.bruce-learning-the-web.online
ssh staging-ssh.bruce-learning-the-web.online
```

In this case the task at hand is as follows:  
Given that I have purchased a domain name from GoDaddy, how can I spin up an EC2 instance and set it up such that when I want to SSH into the instance, I don't call the naked domain name like 
`ec2-35-162-21-39.us-west-2.compute.amazonaws.com` but instead call the purchased domain like 
scripted above.

The steps below assumes that the domain that I am going to purchase is called `bruce-learning-the-web.online`
### We begin with AWS Route 53 console
1. Go to `Hosted zones` tab, click `Create Hosted Zone`, then enter domain name. For now I will choose public hosted zone for the type of hosted zone. 
2. Click into the hosted zone that was just created, then click on `Create Record Set`; I wanted to route SSH traffic to my staging server (an EC2 instance) using the domain name that I purchased, therefore:
    * `ssh-staging.bruce-learning-the-web.online` for name
    * Choose `IPv4` for record type
    * Let `alias` and `TLS` remain to default value
    * Under `Value`, enter the `IPv4` address of the staging server, which you can find under the EC2 console
    * Routing policy will remain default 

### Configure GoDaddy 
* Go to the GoDaddy website and sign in; under `Domains`, click the three dots under the domain that I justed purchase, and click `manage DNS`. 
* Under `Nameservers`, enter the nameservers in `Hosted zones` in AWS Route 53 console