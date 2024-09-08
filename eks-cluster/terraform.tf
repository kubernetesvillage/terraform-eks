terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.31.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
  }

  required_version = "~> 1.6"
}
