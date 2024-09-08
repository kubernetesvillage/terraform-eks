# Terraform EKS

This repository contains Terraform code to provision an Amazon Elastic Kubernetes Service (EKS) cluster. The configuration deploys an EKS cluster with the necessary AWS resources, including worker nodes and networking.

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI configured with appropriate access permissions
- Terraform installed (version 0.14+ recommended)
- IAM permissions to create EKS resources and related AWS infrastructure (e.g., EC2, VPC, IAM roles)

## Setup Instructions

1. **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/terraform-eks.git
    cd terraform-eks/eks-cluster
    ```

2. **Initialize Terraform:**

    Initialize the working directory with the following command:

    ```bash
    terraform init
    ```

3. **Modify Variables:**

    Update the `variables.tf` file with your custom configurations, such as the desired AWS region, cluster name, or any other variables needed for the deployment.

4. **Plan the deployment:**

    Preview the actions Terraform will take to create your resources:

    ```bash
    terraform plan
    ```

5. **Apply the configuration:**

    Deploy the EKS cluster by running the following command:

    ```bash
    terraform apply
    ```

    You will be prompted to confirm the deployment. Type `yes` to proceed.

6. **Access the EKS Cluster:**

    After the deployment is complete, you can access your EKS cluster using the AWS CLI. Run the following command to configure `kubectl`:

    ```bash
    aws eks update-kubeconfig --region <your-region> --name <cluster-name>
    ```

## Outputs

After successful deployment, Terraform will output important information such as:

- EKS Cluster Name
- VPC ID
- Worker Node IAM Role ARN
- Kubernetes API Server Endpoint

Check the `outputs.tf` file to customize the outputs.

## Cleanup

To destroy the infrastructure created by Terraform, run the following command:

```bash
terraform destroy --auto-approve
```

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.
