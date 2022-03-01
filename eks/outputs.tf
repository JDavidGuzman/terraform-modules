output "eks_cluster" {
  value = {
    id       = aws_eks_cluster.main.id
    endpoint = aws_eks_cluster.main.endpoint
    version  = aws_eks_cluster.main.platform_version
    status   = aws_eks_cluster.main.status
  }
}

output "eks_cluster_auth_token" {
  value     = data.aws_eks_cluster_auth.main.token
  sensitive = true
}

output "eks_cluster_ca" {
  value = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
}

output "eks_node_group" {
  value = {
    id             = aws_eks_node_group.main.id
    status         = aws_eks_node_group.main.status
    version        = aws_eks_node_group.main.version
    subnet_ids     = aws_eks_node_group.main.subnet_ids
    ami_type       = aws_eks_node_group.main.ami_type
    ami_version    = aws_eks_node_group.main.release_version
    resources      = aws_eks_node_group.main.resources
    scaling_config = aws_eks_node_group.main.scaling_config
  }
}

output "oidc" {
  value = {
    oidc = aws_iam_openid_connect_provider.main[*].arn
    ingress_controller_role = aws_iam_role.ingress_controller_role[*].arn
  }
}