#!/bin/bash

# Set HOME variable
export HOME=/home/ec2-user

# Load the user's .bashrc file to update the PATH
source /home/ec2-user/.bashrc

# Create necessary directories and set permissions
sudo mkdir -p /home/ec2-user/.cache/pip
sudo mkdir -p /home/ec2-user/anaconda3
sudo mkdir -p /home/ec2-user/anaconda3/envs/sagemaker
sudo chown -R ec2-user:ec2-user /home/ec2-user/.cache
sudo chown -R ec2-user:ec2-user /home/ec2-user/.cache/pip
sudo chown -R ec2-user:ec2-user /home/ec2-user/anaconda3
sudo chmod 777 /home/ec2-user/anaconda3/envs/sagemaker

# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda

# Add conda and mamba to the PATH
export PATH="$HOME/miniconda/bin:$PATH"

# Install Mamba with pip to avoid conda errors
python3 -m pip install ipykernel
python3 -m ipykernel install
pip install mamba

# Create a virtual environment with Python 3.10 using Mamba
mamba create -y -n sagemaker 'python=3.10' ipykernel

# Clean up
rm ~/miniconda.sh
