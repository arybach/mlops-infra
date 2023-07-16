# Complete Metaflow Terraform Example

This directory contains a set of Terraform configuration files for deploying a complete, end-to-end set of resources for running Metaflow on AWS using Terraform modules from [terraform-aws-metaflow](https://github.com/outerbounds/terraform-aws-metaflow). 

This repo only contains configuration for non-Metaflow-specific resources, such as AWS VPC infra and Sagemaker notebook instance; Metaflow-specific parts are provided by reusable modules from [terraform-aws-metaflow](https://github.com/outerbounds/terraform-aws-metaflow).

> Note: The reusable terraform module (source code [here](https://github.com/outerbounds/terraform-aws-metaflow)) itself includes a couple of full "start-from-scratch" examples of:
> * a [minimal Metaflow stack](https://github.com/outerbounds/terraform-aws-metaflow/tree/master/examples/minimal) (using AWS Batch for compute and AWS Step Functions for orchestration)
> * a [Kubernetes based Metaflow stack](https://github.com/outerbounds/terraform-aws-metaflow/tree/master/examples/eks) (using AWS EKS for compute, and Argo Workflows for orchestration)

## Pre-requisites

### Terraform

[Download](https://www.terraform.io/downloads.html) and install terraform 0.14.x or later.

### AWS

AWS credentials should be [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) in your environment.

## Setup

### Infrastructure stack

The infra sub-project provides example networking infrastructure for the Metaflow service. For more details see the [README](infra/README.md)

Copy `example.tfvars` to `prod.tfvars` (or whatever environment name you prefer) and update `env` name and the `region` as needed. These variables are used to construct unique names for infrastructure resources. Best to search and replace env and region in the entire project as some modules are initialized without prod.tfvars.
ENV variable is used for naming metaflow main bucket where all artifacts are stored - pick a value which in combination with the region results in a unique bucket name.

To deploy, initialize Terraform:

```bash
cd infra && terraform init
```

Apply the configuration:

```bash
terraform apply --var-file prod.tfvars
terraform destroy --var-file prod.tfvars
```

### Metaflow stack

The metaflow sub-project uses modules from [terraform-aws-metaflow](https://github.com/outerbounds/terraform-aws-metaflow) to provision the Metaflow service, AWS Step Functions, and AWS Batch resources. 

Copy `example.tfvars` to `prod.tfvars` (or whatever environment name you prefer) and update that `env` name and the `region` as needed. These variables are used to construct unique names for infrastructure resources.

#### Securing the Metadata API (optional)

By default, the Metadata API has basic authentication enabled, but it is exposed to the public internet via Amazon API Gateway. To further restrict access to the API, the `access_list_cidr_blocks` can be set to specify IPs or network cidr blocks that are allowed to access the endpoint, blocking all other access.

Additionally, the `enable_step_functions` flag can be set to false to not provision the AWS Step Functions infrastructure.

To deploy, initialize Terraform:

```bash
cd metaflow && terraform init
```

Apply the configuration:

```
terraform apply --var-file prod.tfvars
terraform destroy --var-file prod.tfvars
```

Once the Terraform executes, configure Metaflow using `metaflow configure import ./metaflow_config_<env>_<region>.json`
Then edit config.json:
sudo nano ~/.metaflowconfig/config.json
fetch api key with aws cli, modify and save it

### Using a custom container image for AWS Batch (optional)

A custom container image can be used by setting the variable `enable_custom_batch_container_registry` to `true`. This will provision an Amazon ECR registry, and the generated Metaflow configuration will have `METAFLOW_BATCH_CONTAINER_IMAGE` and `METAFLOW_BATCH_CONTAINER_REGISTRY` set to point to the private Amazon ECR repository. The container image must then be pushed into the repository before the first flow can be executed.

## add to .bashrc
* export OPENAI_API_KEY=your openai_api_key
* export HUGGINFACE_TOKEN=hugginface_token
* export USDA_API_KEY=google_api_key
* export YOUTUBE_API_KEY=youtube_api_key
* export AWS_ACCESS_KEY_ID=your_aws_access_key_id
* export AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
* export AWS_REGION=your_aws_region
* export ECR_REPO_NAME=your_ecr_repository_name
* *export ECR_REPO_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO_NAME --query 'repositories[0].repositoryUri' --output text --region $AWS_REGION)

## AWS Cli command to create ECR repo (just in case metaflow-created one doesn't suit)
* aws ecr create-repository --repository-name your_ecr_repository_name --region your_aws_region

build and push docker image to ECR using ecr.sh in AMI-docker folder
image uri produced by the shell script (also visible in the AWS EMR console) is used as an input varibale in sagemaker notebook
after metaflow is up and running:

## create compute environment
aws batch create-compute-environment \
    --compute-environment-name sparkhudi-env \
    --type EC2 \
    --state ENABLED \
    --compute-resources minvCpus=1,maxvCpus=4,instanceTypes=m5.large,subnets=subnet-abc123 \
    --service-role arn:aws:iam::0123456789012:role/awsbatchservicerole \
    --region us-west-2

## create batch job definition
aws batch register-job-definition --job-definition-name project-script-name \
--type container \
--container-properties '{
    "image": "388062344663.dkr.ecr.ap-southeast-1.amazonaws.com/sparkhudi:latest",
    "vcpus": 2,
    "memory": 4000,
    "command": ["python", "flow_script_to_run.py"m, "arg1", "arg2" ]
}'

## to creat a queue
aws batch create-job-queue --job-queue-name sparkhudi-queue --priority <QUEUE_PRIORITY> --compute-environment-order order=1,computeEnvironment=<COMPUTE_ENVIRONMENT_ARN>

<QUEUE_PRIORITY>: The priority value for your job queue. Valid values range from -1024 to 1024, where -1024 is the lowest priority and 1024 is the highest.
<COMPUTE_ENVIRONMENT_ARN>: The ARN of the compute environment you want to associate with your job queue.


## to submit a job:
aws batch submit-job --job-name job-name \
--job-definition project-script-name \
--job-queue <your-job-queue-name>


To do this, first copy the output of `metaflow_batch_container_image`.

Then login to the Amazon ECR repository:
```
aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-repository-name>
```

Pull the appropriate image from Docker Hub. In this case, we are using `continuumio/miniconda3:latest`:

```
docker pull continuumio/miniconda3
```

Tag the image:

```
docker tag continuumio/miniconda3:latest <ecr-repository-name>
```

Push the image:

```
docker push <ecr-repository-name>
```

### Amazon Sagemaker Notebook Infrastructure (optional)

The sagemaker-notebook subproject provisions an optional Jupyter notebook with access to the Metaflow API.

Copy `example.tfvars` to `prod.tfvars` (or whatever environment name you prefer) and update that `env` name and the `region` as needed. These variables are used to construct unique names for infrastructure resources.

To deploy, initialize Terraform:

`cd sagemaker && terraform init`

Apply the configuration:

```
terraform apply --var-file prod.tfvars
```

The Amazon Sagemaker notebook url is output as `SAGEMAKER_NOTEBOOK_URL`. Open it to access the notebook.


#### ELK 

To deploy, initialize Terraform:

`cd ec2 && terraform init`

Change .env file to your own values

Apply the configuration:

```
terraform apply
```
kibana should be available on remote_ip:5601
elastic search should be available on remote_ip:9200
