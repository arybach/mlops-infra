## Infra

Stands up the base infrastructure required to deploy a Metaflow stack.

Mostly stands up and configures the Amazon VPC.


## AWS Resources

### Amazon VPC

Amazon Virtual Private Cloud with two public subnets in different availability zones and a private subnet. Also includes an
Elastic IP address for Amazon VPC egress (`elastic_ip_allocation_id`) to allow external services to whitelist access by IP.

After terraform destroy - in aws console go to EFS service and manually delete all FileSystems - they don't get destroyed automatically and hang up deletion of the subnets and the vpc iself as network interfaces to EFS instances remain in use.

