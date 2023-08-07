batch_ecr.sh builds docker image from Dockerfile and updates image with "latest" tag in ECR

## install vault
https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install?in=vault%2Fgetting-started#getting-started-install

GPG is required for the package signing key
$ sudo apt update && sudo apt install gpg

Download the signing key to a new keyring
$ wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

Verify the key's fingerprint
$ gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

The fingerprint must match 798A EC65 4E5C 1542 8C8E 42EE AA16 FCBC A621 E701, which can also be verified at https://www.hashicorp.com/security under "Linux Package Checksum Verification". Please note that there was a previous signing key used prior to January 23, 2023, which had the fingerprint E8A0 32E0 94D8 EB4E A189 D270 DA41 8C88 A321 9F7B. Details about this change are available on the status page: https://status.hashicorp.com/incidents/fgkyvr1kwpdh, https://status.hashicorp.com/incidents/k8jphcczkdkn.

Add the HashiCorp repo
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

apt update!
$ sudo apt update

To see all available packages, you can run: grep ^Package: /var/lib/apt/lists/apt.releases.hashicorp.com*Packages | sort -u

Install a product
$ sudo apt install consul

$ sudo apt install vault

check:
$ vault
$ vault status

## set secrets manually via ui 
https://dev.to/aws-builders/deploying-iac-with-your-secrets-in-terraform-vault-4ggc

start server if not running
$ vault server -dev -mlops-root-token-id="environment"

add to ~/.bashrc
export VAULT_ADDR=https://<vault_server_address>:8200
export VAULT_TOKEN=<vault_access_token>
$ source ~/.bashrc

local Vault server needs to be running and secrets set for the terraform to build custom images

After terraform destroy - in aws console go to EFS service and manually delete all FileSystems - they don't get destroyed automatically and hang up deletion of the subnets and the vpc iself as network interfaces to EFS instances remain in use.

# to test docker image:
docker build -t your-docker-username/metaflow-batch-mlops-apse1:latest -f Dockerfile .
# with the envs baked in (not recommended)
docker build --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY --build-arg AWS_REGION=$AWS_REGION --build-arg OPENAI_API_KEY=$OPENAI_API_KEY --build-arg HUGGING_FACE_TOKEN=$HUGGING_FACE_TOKEN -t arybach/metaflow-batch-mlops-apse1:latest -f Dockerfile.batch .

docker push your-docker-username/metaflow-batch-mlops-apse1:latest

# check status:
docker run --user metaflow -it --rm -v "/home/groot/.metaflowconfig/config.json:/home/metaflow/.metaflowconfig/config.json" arybach/metaflow-batch-mlops-apse1:latest metaflow status

# try:
docker run --user metaflow -it --rm -v "/home/groot/.metaflowconfig/config.json:/home/metaflow/.metaflowconfig/config.json" arybach/metaflow-batch-mlops-apse1:latest pip install --upgrade metaflow

# before running this
docker run --user metaflow -it --rm -v "/home/groot/.metaflowconfig/config.json:/home/metaflow/.metaflowconfig/config.json" arybach/metaflow-batch-mlops-apse1:latest python helloworld.py run ### any helloworld.py will do

# check connection
curl -v -H 'x-api-key:Aezv03xLrY2UUgETMFCWG3hUP70rjInZ2d9dPvBV' https://ydxq2ybdtk.execute-api.ap-southeast-1.amazonaws.com/api/flows

# submitting an aws batch job from the aws cli
aws batch submit-job \
    --job-name helloworld \
    --job-queue arn:aws:batch:ap-southeast-1:388062344663:job-queue/metaflow-mlops-apse1 \
    --job-definition helloworld:1 \
    --parameters '{"arg1": "hello", "arg2": "world"}' \
    --container-overrides '{"command": ["python", "helloworld.py", "--arg1", "$arg1", "--arg2", "$arg2"]}'

## To test-build docker ECR image:
batch_ecr.sh builds docker image from Dockerfile and updates image with "latest" tag in ECR

cd batch

cp ~/.metaflowconfig/config.json .
echo "AWS_ACCESS_KEY_ID=$AWS_ACCES_KEY_ID" > .env
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCES_KEY" > .env
echo "AWS_REGION=$AWS_REGION" > .env
echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env
echo "HUGGING_FACE_TOKEN=$HUGGING_FACE_TOKEN" >> .env
echo "USDA_API_KEY=$USDA_API_KEY" >> .env
echo "ES_PASSWORD=$ES_PASSWORD" >> .env

docker build -t arybach/emr-ecr-custom:latest -f Dockerfile.emr .
docker push arybach/emr-ecr-custom:latest

# after infra module is terraform applied - image pushed into ECR repository can be validated with:
amazon-emr-serverless-image validate-image -r emr-6.10.0 -t spark \
-i 388062344663.dkr.ecr.ap-southeast-1.amazonaws.com/emr_ecr_repo:latest