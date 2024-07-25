module "EKS" {
  source          = "./eksmodule"
  cluster_name    = var.cluster_name
  cluster_version = var.eks_cluster_version
  subnet_ids      = var.subnet_ids
  cluster_encryption_config = {
    provider_key_arn = var.kms_key_id
    resources        = ["secrets"]
  }
  create_kms_key                            = false
  vpc_id                                    = var.vpc_id
  cluster_security_group_name               = "eks-cluster-sg"
  cluster_security_group_additional_rules   = {}
  node_security_group_name                  = "eks-nodegrp-sg"
  node_security_group_additional_rules      = {}
  create_iam_role                           = true
  iam_role_name                             = "eksrole"
  iam_role_description                      = "role for eks project"
  iam_role_use_name_prefix                  = false
  cluster_encryption_policy_use_name_prefix = false
  cluster_encryption_policy_name            = "eks-cluster-encryption-policy"
  enable_cluster_creator_admin_permissions  = true
  cluster_endpoint_public_access            = true
  eks_managed_node_groups = {
    default_node_group = {
      name                       = "worker-nodegrp-1"
      use_name_prefix            = false
      use_custom_launch_template = false
      disk_size                  = var.eks_node_group_disk_size
      desired_size               = var.eks_node_group_desired_size
      min_size                   = var.eks_node_group_min_size
      max_size                   = var.eks_node_group_max_size
      create_iam_role            = true
      iam_role_name              = "eksnode-role"
      iam_role_use_name_prefix   = false
    }
  }
}
# Fetch the EKS cluster info after it's created
data "aws_eks_cluster" "cluster" {
  name = module.EKS.cluster_name

  depends_on = [module.EKS]
}

# Configure the Kubernetes provider with dynamic values
provider "kubernetes" {
  host                   = module.EKS.cluster_endpoint
  cluster_ca_certificate = base64decode(module.EKS.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.EKS.cluster_name]
  }
}

# Configure the Helm provider with dynamic values
provider "helm" {
  kubernetes {
    host                   = module.EKS.cluster_endpoint
    cluster_ca_certificate = base64decode(module.EKS.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.EKS.cluster_name]
    }
  }
}

# Create the Gatekeeper namespace
resource "kubernetes_namespace" "gatekeeper" {
  metadata {
    name = "gatekeeper-system"
  }
  #depends_on = [module.EKS]
}

# Install Gatekeeper via Helm
resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  create_namespace = true
  namespace  = kubernetes_namespace.gatekeeper.metadata[0].name

  depends_on = [kubernetes_namespace.gatekeeper]
}
# Create the Prometheus namespace
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "monitoring"
  }
  #depends_on = [module.EKS]
}
# Install Prometheus via Helm
resource "helm_release" "prometheus" {
  name       = "kube-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  create_namespace =  true
  namespace  = "monitoring"

  depends_on = [kubernetes_namespace.prometheus]
}

# Define the path to your Gatekeeper templates and constraints directories
locals {
  gatekeeper_templates_dir   = "${path.module}/gatekeeper_policies_constraints-templates"
  gatekeeper_constraints_dir = "${path.module}/gatekeeper_policies_constraints"
}

# Get the list of all YAML files in the templates directory
data "local_file" "gatekeeper_templates" {
  for_each = fileset(local.gatekeeper_templates_dir, "*.yaml")

  filename = "${local.gatekeeper_templates_dir}/${each.value}"
}

# Get the list of all YAML files in the constraints directory
data "local_file" "gatekeeper_constraints" {
  for_each = fileset(local.gatekeeper_constraints_dir, "*.yaml")

  filename = "${local.gatekeeper_constraints_dir}/${each.value}"
}

# output "gate" {
#   value = {for k,v in data.local_file.gatekeeper_constraints : k =>yamldecode(v.content) }
# }

# Apply each Gatekeeper template
resource "kubernetes_manifest" "gatekeeper_templates" {
  for_each = data.local_file.gatekeeper_templates
  
  manifest = yamldecode(each.value.content)

  depends_on = [helm_release.gatekeeper, helm_release.prometheus]
}

# Apply each Gatekeeper constraint
resource "kubernetes_manifest" "gatekeeper_constraints" {
  for_each = data.local_file.gatekeeper_constraints

  manifest = yamldecode(each.value.content)

  depends_on = [kubernetes_manifest.gatekeeper_templates]
}
