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

# Redirect output to a log file
exec > >(tee -i install.log)
exec 2>&1

# Attempt to fix Yarn APT key/source if a Yarn repo is present and the keyring is missing.
# This function is idempotent and will not abort the script if it fails.
fix_yarn_key_if_needed() {
    if grep -R --quiet "dl.yarnpkg.com" /etc/apt 2>/dev/null; then
        sudo rm -f /etc/apt/sources.list.d/yarn.list
        echo "Fixing Yarn APT repo (non-fatal)..."
        sudo mkdir -p /usr/share/keyrings
        if curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg; then
            echo "Yarn keyring added."
            echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian stable main" \
                | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
            sudo apt-get update || true
        else
            echo "Warning: failed to fix Yarn key; continuing..."
        fi
    fi
    return 0
}

# Function to install AWS CLI
install_aws() {
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || { echo "AWS CLI download failed. Exiting."; exit 1; }
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    echo "AWS CLI installation complete."
}

# Function to install eksctl
install_eksctl() {
    echo "Installing eksctl..."
    PLATFORM=$(uname -s)_amd64
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" || { echo "eksctl download failed. Exiting."; exit 1; }
    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
    sudo mv /tmp/eksctl /usr/local/bin
    echo "eksctl installation complete."
}

# Function to install kubectl
install_kubectl() {
    echo "Installing kubectl..."
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) BIN_ARCH="amd64" ;;
        aarch64) BIN_ARCH="arm64" ;;
        *) echo "Unsupported architecture: $ARCH. Exiting."; exit 1 ;;
    esac
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$BIN_ARCH/kubectl" || { echo "kubectl download failed. Exiting."; exit 1; }
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    echo "kubectl installation complete."
}

# Function to install Terraform
install_terraform() {
    echo "Installing Terraform..."
    if [[ "$OS" == "ubuntu" ]]; then
        fix_yarn_key_if_needed || true
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update || echo "Warning: apt-get update reported errors; attempting to install terraform anyway..."
        sudo apt-get install -y terraform || { echo "Terraform install failed. Exiting."; exit 1; }
    elif [[ "$OS" == "amzn" ]]; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        sudo yum -y install terraform || { echo "Terraform install failed. Exiting."; exit 1; }
    else
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y install terraform || { echo "Terraform install failed. Exiting."; exit 1; }
    fi
    echo "Terraform installation complete."
}

# Function to install OpenTofu
install_opentofu() {
    echo "Installing OpenTofu..."
    if [[ "$OS" == "ubuntu" ]]; then
        fix_yarn_key_if_needed || true
        sudo apt-get update -y
        sudo apt-get install -y uuid-runtime jq || { echo "Package installation failed. Exiting."; exit 1; }
        curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh || { echo "OpenTofu installer download failed. Exiting."; exit 1; }
        chmod +x install-opentofu.sh
        ./install-opentofu.sh --install-method deb
        rm -f install-opentofu.sh
    else
        sudo yum update -y
        sudo yum install -y yum-utils uuid jq || { echo "Package installation failed. Exiting."; exit 1; }
        curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh || { echo "OpenTofu installer download failed. Exiting."; exit 1; }
        chmod +x install-opentofu.sh
        ./install-opentofu.sh --install-method rpm
        rm -f install-opentofu.sh
    fi
    echo "OpenTofu installation complete."
}

# Function to install jq, envsubst, and bash-completion
install_utilities() {
    echo "Installing utilities..."
    if [[ "$OS" == "ubuntu" ]]; then
        fix_yarn_key_if_needed || true
        sudo apt-get update -y
        sudo apt-get install -y jq gettext-base bash-completion moreutils || { echo "Utilities installation failed. Exiting."; exit 1; }
    else
        sudo yum -y install jq gettext bash-completion moreutils || { echo "Utilities installation failed. Exiting."; exit 1; }
    fi
    echo "Utilities installation complete."
}

# Function to install yq
install_yq() {
    echo "Installing yq..."
    yq_version='4.44.3'
    curl -sLO "https://github.com/mikefarah/yq/releases/download/v$yq_version/yq_linux_amd64" || { echo "yq download failed. Exiting."; exit 1; }
    chmod +x ./yq_linux_amd64
    sudo mv ./yq_linux_amd64 /usr/local/bin/yq
    echo "yq installation complete."
}

# Function to install Helm
install_helm() {
    echo "Installing Helm..."
    helm_version='3.16.2'
    curl -sLO "https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz" || { echo "Helm download failed. Exiting."; exit 1; }
    tar zxf helm-v$helm_version-linux-amd64.tar.gz
    sudo mv ./linux-amd64/helm /usr/local/bin
    rm -rf linux-amd64/ helm-v$helm_version-linux-amd64.tar.gz
    echo "Helm installation complete."
}

# Function to install kubeseal
install_kubeseal() {
    echo "Installing kubeseal..."
    kubeseal_version='0.27.2'
    curl -sLO "https://github.com/bitnami-labs/sealed-secrets/releases/download/v$kubeseal_version/kubeseal-$kubeseal_version-linux-amd64.tar.gz" || { echo "kubeseal download failed. Exiting."; exit 1; }
    tar xfz kubeseal-$kubeseal_version-linux-amd64.tar.gz
    chmod +x kubeseal
    sudo mv ./kubeseal /usr/local/bin
    rm kubeseal-$kubeseal_version-linux-amd64.tar.gz
    echo "kubeseal installation complete."
}

# Function to check if a binary is installed
# OpenTofu installs as 'tofu', not 'opentofu'
check_binary() {
    local bin="$1"
    local check_cmd="$bin"
    [ "$bin" = "opentofu" ] && check_cmd="tofu"
    if ! command -v $check_cmd &> /dev/null; then
        echo "$bin not found. Installing $bin..."
        if [ "$bin" = "jq" ] || [ "$bin" = "envsubst" ]; then
            install_utilities
        else
            install_$bin
        fi
    else
        echo "$bin is already installed."
    fi
}

# Check CPU architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
    echo "Error: This script only supports Intel/AMD64 or ARM64 architectures. Detected architecture: $ARCH."
    exit 1
fi

# Determine OS type
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "Operating System detected: $OS."
else
    echo "Cannot determine operating system type. Exiting."
    exit 1
fi

# OS compatibility check
if [[ "$OS" != "amzn" && "$OS" != "centos" && "$OS" != "rhel" && "$OS" != "ubuntu" ]]; then
    echo "Unsupported OS: $OS. This script supports Amazon Linux, CentOS, RHEL, or Ubuntu only."
    exit 1
fi

# Check and install required binaries
echo "Checking and installing required binaries..."
check_binary aws
check_binary eksctl
check_binary kubectl
check_binary terraform
check_binary opentofu
check_binary jq
check_binary yq
check_binary helm
check_binary kubeseal

echo "Pre-deployment checks and installations are complete."
