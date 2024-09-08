#!/bin/bash

set -e
set -x  # Enables debug mode (shows commands as they are executed)

echo "====================================================================="
echo "    Pre-deployment Script By peachycloudsecurity                      "
echo "====================================================================="
echo ""
echo "Initializing the setup of required dependencies."
echo ""
echo ""

# Function to install AWS CLI
install_aws() {
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    echo "AWS CLI installation complete."
}

# Function to install eksctl
install_eksctl() {
    echo "Installing eksctl..."
    eksctl_version='0.164.0'
    eksctl_checksum='2ed5de811dd26a3ed041ca3e6f26717288dc02dfe87ac752ae549ed69576d03e'
    curl -sLO "https://github.com/weaveworks/eksctl/releases/download/v$eksctl_version/eksctl_Linux_amd64.tar.gz"
    echo "$eksctl_checksum eksctl_Linux_amd64.tar.gz" > eksctl_Linux_amd64.tar.gz.sha256
    sha256sum --check eksctl_Linux_amd64.tar.gz.sha256
    tar -xzf eksctl_Linux_amd64.tar.gz
    sudo mv ./eksctl /usr/local/bin
    rm eksctl_Linux_amd64.tar.gz
    echo "eksctl installation complete."
}

# Function to install kubectl
install_kubectl() {
    echo "Installing kubectl..."
    kubectl_version='1.27.7'
    kubectl_checksum='e5fe510ba6f421958358d3d43b3f0b04c2957d4bc3bb24cf541719af61a06d79'
    curl -LO "https://dl.k8s.io/release/v$kubectl_version/bin/linux/amd64/kubectl"
    echo "$kubectl_checksum kubectl" > kubectl.sha256
    sha256sum --check kubectl.sha256
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin
    rm kubectl.sha256
    echo "kubectl installation complete."
}

# Function to install Helm
install_helm() {
    echo "Installing Helm..."
    helm_version='3.10.1'
    helm_checksum='c12d2cd638f2d066fec123d0bd7f010f32c643afdf288d39a4610b1f9cb32af3'
    curl -sLO "https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz"
    echo "$helm_checksum helm-v$helm_version-linux-amd64.tar.gz" > helm.tar.gz.sha256
    sha256sum --check helm.tar.gz.sha256
    tar zxf helm-v$helm_version-linux-amd64.tar.gz
    sudo mv ./linux-amd64/helm /usr/local/bin
    rm -rf linux-amd64/ helm-v$helm_version-linux-amd64.tar.gz
    echo "Helm installation complete."
}

# Function to install kubeseal
install_kubeseal() {
    echo "Installing kubeseal..."
    kubeseal_version='0.18.4'
    kubeseal_checksum='2e765b87889bfcf06a6249cde8e28507e3b7be29851e4fac651853f7638f12f3'
    curl -sLO "https://github.com/bitnami-labs/sealed-secrets/releases/download/v$kubeseal_version/kubeseal-$kubeseal_version-linux-amd64.tar.gz"
    echo "$kubeseal_checksum kubeseal-$kubeseal_version-linux-amd64.tar.gz" > kubeseal.sha256
    sha256sum --check kubeseal.sha256
    tar xfz kubeseal-$kubeseal_version-linux-amd64.tar.gz
    chmod +x kubeseal
    sudo mv ./kubeseal /usr/local/bin
    rm kubeseal-$kubeseal_version-linux-amd64.tar.gz
    echo "kubeseal installation complete."
}

# Function to install yq
install_yq() {
    echo "Installing yq..."
    yq_version='4.30.4'
    yq_checksum='30459aa144a26125a1b22c62760f9b3872123233a5658934f7bd9fe714d7864d'
    curl -sLO "https://github.com/mikefarah/yq/releases/download/v$yq_version/yq_linux_amd64"
    echo "$yq_checksum yq_linux_amd64" > yq.sha256
    sha256sum --check yq.sha256
    chmod +x ./yq_linux_amd64
    sudo mv ./yq_linux_amd64 /usr/local/bin/yq
    rm yq.sha256
    echo "yq installation complete."
}

# Function to install ec2-instance-selector
install_ec2_instance_selector() {
    echo "Installing EC2 instance selector..."
    ec2_instance_selector_version='2.4.1'
    ec2_instance_selector_checksum='dfd6560a39c98b97ab99a34fc261b6209fc4eec87b0bc981d052f3b13705e9ff'
    curl -sLO "https://github.com/aws/amazon-ec2-instance-selector/releases/download/v$ec2_instance_selector_version/ec2-instance-selector-linux-amd64"
    echo "$ec2_instance_selector_checksum ec2-instance-selector-linux-amd64" > ec2-instance-selector.sha256
    sha256sum --check ec2-instance-selector.sha256
    chmod +x ec2-instance-selector-linux-amd64
    sudo mv ./ec2-instance-selector-linux-amd64 /usr/local/bin/ec2-instance-selector
    rm ec2-instance-selector.sha256
    echo "EC2 instance selector installation complete."
}

# Function to install Terraform
install_terraform() {
    echo "Installing Terraform..."
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum makecache fast
    sudo yum -y install terraform
    echo "Terraform installation complete."
}

# Function to install jq, envsubst, and bash-completion
install_utilities() {
    echo "Installing utilities..."
    sudo yum -y install jq gettext bash-completion moreutils
    echo "Utilities installation complete."
}

# Check if a binary is installed and install if not
check_binary() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 could not be found. Installing $1..."
        if [ "$1" = "jq" ] || [ "$1" = "envsubst" ]; then
            install_utilities
        else
            install_$1
        fi
    else
        echo "$1 is already installed."
    fi
}

# Check and install required binaries
echo "Checking and installing required binaries..."
check_binary aws
check_binary eksctl
check_binary kubectl
check_binary terraform
check_binary jq
check_binary helm
check_binary kubeseal
check_binary yq
check_binary ec2_instance_selector
check_binary envsubst

echo "Pre-deployment checks and installations are complete."
