terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95.0, < 6.0.0"
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
      version = ">= 4.0.0"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }

  required_version = ">= 1.5.0"
}
