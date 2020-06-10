# Static domain name for SSH 
After spawning an EC2 instance on AWS, the canonical way of interacting with the instance is using 
SSH for remote log-in through the public DNS address that looks something like this:
```bash
ssh -i "/path/to/key.pem" admin@ec2-xx-xxx-xx-xx.us-west-2.compute.amazonaws.com
```
This is fine if I am the only person administering the remote server; however, if there are 10 developers who log into the server, then each time the public DNS address changes (If a system reboot or instance upgrade happens), each of the 10 developers will need to change his/her login individually. Instead, it would be really nice if there is a single point of entry such that changing the public DNS address of the remote server requires only one manual change, and all downstream developers can SSH into the new remote server instance without even noticing.

The following section will describe the process by which I am able to route a specific domain name (which I purchased from godaddy.com) to an EC2 instance such that I can SSH into the EC2 instance using the following command 
```bash 
ssh -i "/path/to/key.pem" admin@staging.purchased-domain.name
```
where `some.custom-domain.name` is the domain name purchased from commercial sites like GoDaddy.

## Setting up remote server 
The journey begins by spinning up an EC2 instance that will be referred from this point on as "the remote server". For my personal setting, I used a Debian 10 AMI, which comes with SSH server by 
default.

Note that ssh server by default listens at port 22, so make sure that the security group for the remote server is set such that port 80 is open to 0.0.0.0/0.

After the remote server starts running and apache2 is installed, take note of the remote server's 
IPv4 address.

## Purchase a domain name 
Follow domain name vendor's instruction to purchase a domain name. For simplicity, suppose that 
I purchased the domain name `purchased-domain.name`.

## AWS Route 53 
On Route 53's console, create a new hosted zone. Enter the domain name that you just purchased, then select "Public Hosted Zone". After the hosted zone is created, click into it, then create a new record set. I chose `staging.purchased-domain.name` because I originally intended the remote server to be a staging server. Select IPv4 for record type, "No" for alias, 300ms for TTL, then enter the IPv4 address of the remote server in "Value". Set routing policy to "Simple", then hit "Create".

Before we leave the route 53 console, mark the addresses of the name servers; they typically look like these, and will be referred to as AWS nameservers:
```
ns-xxx.awsdns-xx.com
ns-xxx.awsdns-xx.net
ns-xxxx.awsdns-xx.co.uk
ns-xxxx.awsdns-xx.org
```

## Configuring custom nameservers on domain name vendor 
I went with GoDaddy for domain name vendor. Go to the DNS settings for the domain name that I just purchased, then find the field for entering nameserver addresses and enter the addresses marked above. After saving the changes, wait for up to 24 hours for those changes to take effect.

At this point, routing goes as follows: when I request connection to `staging.purchased-domain.name`, it will first be routed to GoDaddy, which looks up the nameservers on AWS, and route the traffic to AWS' nameservers. AWS nameservers will then look up the record set, find that `staging.purchased-domain.name` is routed to the remote server, and finally route the traffic to the remote 
server.

