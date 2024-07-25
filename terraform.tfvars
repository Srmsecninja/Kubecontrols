# ARN of the IAM role used by the EKS cluster
cluster_role_arn = "arn:aws:iam::219872127195:role/testEKS"

# ARN of the IAM role used by the EKS worker nodes
node_role_arn = "arn:aws:iam::219872127195:role/eksnoderole"

# List of subnet IDs to be used by the EKS cluster
subnet_ids = [
  "subnet-2e3a8c75",
  "subnet-c0335f89",
]

# ID of the VPC to be used by the EKS cluster
vpc_id = "vpc-2f1fee49"

assume_role_arn             = "arn:aws:iam::219872127195:role/tfrole"
kms_key_id                  = "arn:aws:kms:us-east-1:219872127195:key/c873350f-9d7f-4eb6-8341-26bcafdae154"
ami_id                      = "ami-07a09baf6da06052d"
eks_cluster_version         = "1.29"
eks_node_group_disk_size    = 30
eks_node_group_desired_size = 2
eks_node_group_max_size     = 2
eks_node_group_min_size     = 1
cluster_name                = "myOPAproject_v02"
