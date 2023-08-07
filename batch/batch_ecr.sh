#!/bin/bash

# Write environment variables to .env file
echo "AWS_ACCESS_KEY_ID=$3" > .env
echo "AWS_SECRET_ACCESS_KEY=$4" >> .env
echo "AWS_REGION=$5" >> .env
echo "OPENAI_API_KEY=$6" >> .env
echo "HUGGING_FACE_TOKEN=$7" >> .env
echo "USDA_API_KEY=$8" >> .env
echo "ES_PASSWORD=$9" >> .env
echo "WANDB_API_KEY=$10" >> .env

# Copy metaflow config file
cp ~/.metaflowconfig/config.json .

# Set AWS region
AWS_REGION=$5
# Set ECR repository name
ECR_REPO_URI=$2
# Set ECR image and tag name
IMAGE_NAME="metaflow-batch-mlops-apse1"
TAG_NAME="latest"        

# Set S3 bucket to upload to
S3_BUCKET=$1
echo "Parameter 1: S3_BUCKET = $S3_BUCKET" >> output.txt

# Build Docker image
docker build -t $IMAGE_NAME -f Dockerfile.batch .

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

# Tag Docker image
docker tag $IMAGE_NAME $ECR_REPO_URI:$TAG_NAME

# Push Docker image to ECR
docker push $ECR_REPO_URI:$TAG_NAME

# Check if image is available
# aws ecr describe-images --repository-name $ECR_REPO_URI --image-ids imageTag=$TAG_NAME --region $AWS_REGION

# Write ECR repository URI to file
echo $ECR_REPO_URI:$TAG_NAME > batch_image_tag.txt

# clean up
rm .env