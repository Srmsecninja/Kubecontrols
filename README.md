# Kubecontrols

Kubernetes gatekeeper controls to secure deployments

## Overview

**Kubecontrols** is an Infrastructure-as-Code (IaC) project that sets up a secure Amazon EKS (Elastic Kubernetes Service) cluster with **Open Policy Agent (OPA) Gatekeeper** for policy enforcement and security controls. This project combines Terraform for infrastructure provisioning, Kubernetes for policy management, and Python utilities for deployment automation.

## Features

- 🏗️ **Automated EKS Cluster Provisioning** - Deploy production-ready EKS clusters using Terraform
- 🔒 **Policy Enforcement** - Enforce security policies at admission time using Gatekeeper
- 📊 **Monitoring** - Built-in Prometheus monitoring stack for observability
- 🔐 **Encryption** - KMS-encrypted secrets in the cluster
- 🚀 **GitOps Ready** - GitLab CI/CD pipeline for automated deployments
- 🔄 **Policy-as-Code** - Version-controlled security constraints

## Architecture

```
┌─────────────────────────────────────────┐
│         AWS Account (EKS Cluster)       │
├─────────────────────────────────────────┤
│  ┌──────────────────────────────────┐   │
│  │   Gatekeeper Namespace           │   │
│  │  (gatekeeper-system)             │   │
│  │  ├─ ConstraintTemplates          │   │
│  │  └─ Constraints (Policies)       │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │   Monitoring Namespace           │   │
│  │  (monitoring)                    │   │
│  │  └─ Prometheus Stack             │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │   Worker Nodes                   │   │
│  │  (Managed Node Groups)           │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## Prerequisites

Before deploying Kubecontrols, ensure you have:

- **AWS Account** with appropriate IAM permissions for EKS, VPC, KMS, and IAM roles
- **Terraform** >= 1.0
- **kubectl** >= 1.24
- **AWS CLI** configured with credentials
- **Helm** >= 3.0
- **Python** >= 3.8 (for deployment utilities)

## Project Structure

```
Kubecontrols/
├── eks.tf                          # EKS cluster and Gatekeeper/Prometheus setup
├── provider.tf                     # Terraform provider configuration
├── data.tf                         # Data sources
├── variables.tf                    # Input variables
├── terraform.tfvars               # Variable values
├── apply_policies.py              # Python script for applying constraints
├── constraint_unapprovedimages.yaml    # Gatekeeper constraint for image approval
├── constraint_kubesecrets.yaml         # Gatekeeper constraint for secret handling
├── .gitlab-ci.yml                 # GitLab CI/CD pipeline
├── .terraform.lock.hcl            # Terraform dependency lock file
├── terraform.tfstate              # Terraform state (production)
├── terraform.tfstate.backup       # Terraform state backup
├── .gitignore                     # Git ignore rules
└── README.md                      # This file
```

## Security Policies / Constraints

### 1. **Approved Container Images** (`constraint_unapprovedimages.yaml`)
Enforces that only container images from approved ECR repositories can be deployed.

**Policy Details:**
- Allowed Repository: `219872127195.dkr.ecr.us-east-1.amazonaws.com/myecrproject`
- Scope: Applied to Pod deployments
- Impact: Prevents deployment of unauthorized container images

### 2. **Kubernetes Secrets Management** (`constraint_kubesecrets.yaml`)
Controls the usage and handling of Kubernetes secrets.

**Policy Details:**
- Type: K8sDisallowedSecret
- Status: Currently disabled (can be enabled for production)
- Use Case: Prevent direct use of Kubernetes secrets in favor of external secret management

## Installation & Setup

### Step 1: Clone the Repository

```bash
cd /Users/srm/Desktop/MyCode/K8
git clone https://github.com/Srmsecninja/Kubecontrols.git
cd Kubecontrols
```

### Step 2: Configure Variables

1. Copy the example template:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your environment-specific values:
```hcl
cluster_name                  = "my-eks-cluster"
eks_cluster_version           = "1.29"
vpc_id                        = "vpc-xxxxxxxx"
subnet_ids                    = ["subnet-xxxxxxxx", "subnet-xxxxxxxx"]
kms_key_id                    = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
cluster_role_arn              = "arn:aws:iam::ACCOUNT_ID:role/eksrole"
node_role_arn                 = "arn:aws:iam::ACCOUNT_ID:role/eksnode-role"
assume_role_arn               = "arn:aws:iam::ACCOUNT_ID:role/terraform-role"
eks_node_group_disk_size      = 30
eks_node_group_desired_size   = 2
eks_node_group_min_size       = 1
eks_node_group_max_size       = 4
```

3. Ensure `.gitignore` includes `terraform.tfvars` - **NEVER commit this file** as it contains sensitive AWS credentials and infrastructure details.

### Step 3: Initialize and Plan Terraform

```bash
terraform init
terraform plan -out=planfile
```

### Step 4: Apply Infrastructure

```bash
terraform apply planfile
```

This will:
- Provision the EKS cluster
- Create managed node groups
- Install Gatekeeper
- Install Prometheus monitoring stack

### Step 5: Configure kubectl

```bash
aws eks update-kubeconfig --name <cluster-name> --region us-east-1
kubectl get nodes  # Verify connectivity
```

## Applying Security Constraints

### Option 1: Manual Application

```bash
kubectl apply -f constraint_unapprovedimages.yaml
kubectl apply -f constraint_kubesecrets.yaml
```

### Option 2: Using Python Script

The `apply_policies.py` script automates constraint application:

```bash
# Prepare YAML files in yaml_files directory
mkdir yaml_files
cp constraint_*.yaml yaml_files/

# Run the script
python3 apply_policies.py
```

**Script Behavior:**
1. Scans `yaml_files/` directory for YAML files
2. Applies ConstraintTemplates first
3. Then applies Constraints
4. Handles errors gracefully

## Configuration

### Key Terraform Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | EKS cluster name | Required |
| `cluster_version` | EKS Kubernetes version | `1.27` |
| `vpc_id` | VPC for cluster placement | Required |
| `subnet_ids` | Subnets for cluster placement | Required |
| `kms_key_id` | KMS key for secret encryption | Required |
| `eks_node_group_desired_size` | Desired number of nodes | `2` |
| `eks_node_group_min_size` | Minimum nodes in auto-scaling | `1` |
| `eks_node_group_max_size` | Maximum nodes in auto-scaling | `4` |

### Security Configuration

**Encryption:**
- Secrets are encrypted at rest using AWS KMS
- KMS key ARN must be provided in variables

**Network Access:**
- Cluster endpoint is publicly accessible (configurable)
- Node security groups restrict traffic appropriately

**IAM Roles:**
- EKS cluster role: `eksrole`
- Node role: `eksnode-role`
- Cluster creator has admin permissions

## Monitoring

Prometheus stack is automatically deployed in the `monitoring` namespace:

### Access Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090 in browser
```

### Access Grafana (if included in stack)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:3000
# Default credentials: admin / prom-operator
```

## CI/CD Pipeline

The `.gitlab-ci.yml` file defines a GitLab CI/CD pipeline with two stages:

### Pipeline Stages

1. **Plan Stage**
   - Initializes Terraform
   - Runs `terraform plan`
   - Generates plan artifact
   - Tags: `lq`

2. **Apply Stage**
   - Depends on successful plan
   - Executes `terraform apply`
   - Tags: `lq`
Security & Sensitive Data

### ⚠️ Important Security Notice

This project contains infrastructure configuration that connects to sensitive AWS resources. Follow these guidelines:

**DO NOT commit to version control:**
- `terraform.tfvars` - Contains AWS credentials and IDs
- `.env` files - Environment variables
- `kubeconfig` files - Kubernetes cluster credentials
- `*.key` or `*.pem` files - Private keys

**Best Practices:**
1. Use `terraform.tfvars.example` as a template
2. Create local `terraform.tfvars` (ignored by git)
3. Use AWS SSO or IAM role assumption instead of hardcoded credentials
4. Store secrets in AWS Secrets Manager or HashiCorp Vault
5. Enable MFA for AWS account access
6. Use separate AWS accounts for development, staging, and production
7. Regularly audit Git history for accidentally committed secrets

**If you accidentally commit sensitive data:**
1. Immediately rotate affected AWS credentials
2. Use `git-filter-branch` or BFG to remove from history
3. Force push to update remote repository
4. Notify your security team

## 
### Running the Pipeline

Push to GitLab to trigger the pipeline:

```bash
git push origin main
```

## Troubleshooting

### Issue: Gatekeeper pods not running

```bash
kubectl get pods -n gatekeeper-system
kubectl describe pod <pod-name> -n gatekeeper-system
```

### Issue: Constraints not being enforced

```bash
# Check constraint status
kubectl get constraints
kubectl describe constraint <constraint-name>

# Check audit logs
kubectl logs -n gatekeeper-system -l app=gatekeeper
```

### Issue: Kubernetes provider authentication errors

Ensure AWS CLI is configured:

```bash
aws sts get-caller-identity
aws eks get-token --cluster-name <cluster-name>
```

## Extending the Project

### Adding New Constraints

1. Create a new constraint file: `constraint_<policy-name>.yaml`
2. Define the constraint using Gatekeeper API
3. Apply using: `kubectl apply -f constraint_<policy-name>.yaml`

Example template:
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sCustomConstraint
metadata:
  name: my-constraint
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    # Your parameters here
```

### Customizing Node Groups

Edit the `eks_managed_node_groups` block in `eks.tf` to add additional node groups with different configurations.

## Best Practices

1. **State Management** - Use remote state storage (S3 + DynamoDB) instead of local state
2. **RBAC** - Enable and configure Kubernetes RBAC for fine-grained access control
3. **Network Policies** - Implement Kubernetes network policies in addition to Gatekeeper
4. **Audit Logging** - Enable CloudTrail and EKS control plane logging
5. **Secrets Management** - Use AWS Secrets Manager or HashiCorp Vault instead of Kubernetes Secrets
6. **Policy Review** - Regularly audit and update constraints for evolving security needs

## Support & Contribution

For issues, questions, or improvements:

- GitHub Issues: [Kubecontrols Issues](https://github.com/Srmsecninja/Kubecontrols/issues)
- Pull Requests: [Kubecontrols Pull Requests](https://github.com/Srmsecninja/Kubecontrols/pulls)

## License

This project is licensed under the MIT License - see LICENSE file for details.

## References

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Open Policy Agent Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Last Updated:** May 28, 2026
