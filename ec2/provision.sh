#!/bin/bash

sudo yum update -y && sudo yum install -y wget bzip2 git

# Install Python 3.10 if needed
if ! command -v python3.10 &> /dev/null; then
    sudo yum install -y python3.10
fi

# Set up Python 3.10 as the default version
if ! grep -q "alias python=python3.10" ~/.bashrc; then
    echo 'alias python=python3.10' >> ~/.bashrc
fi

# Install Docker and Docker Compose if needed
if ! command -v docker &> /dev/null; then
    sudo yum install -y docker
    sudo systemctl enable docker
    sudo systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Add ec2-user to the docker group
sudo usermod -aG docker ec2-user

# Install Miniconda if needed
if ! command -v conda &> /dev/null; then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p $HOME/miniconda
    echo 'export PATH=$HOME/miniconda/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc
    rm miniconda.sh
fi
