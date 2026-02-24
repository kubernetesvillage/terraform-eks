provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "peachycloud-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "peachycloud-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  map_public_ip_on_launch = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # 20.21.0

  cluster_name    = local.cluster_name
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  cluster_endpoint_public_access = true

  authentication_mode = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"

  }

  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }

  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }
    coredns = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    main = {
      name = "peachycloud-node-group"

      instance_types = ["t3.small"]
      subnet_ids     = module.vpc.public_subnets

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Control-plane ↔ node traffic (e.g. CoreDNS → API server)
      attach_cluster_primary_security_group = true

      # IRSA: pods need IMDS hop limit 2 to assume role via web identity
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      # Node role must have CNI policy so aws-node can assign pod IPs
      iam_role_attach_cni_policy = true
    }
  }
}

# EBS CSI: IRSA + addon (outside cluster_addons to avoid cycle with module.eks)
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.33.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = { "eks_addon" = "ebs-csi", "terraform" = "true" }
}
