data "aws_iam_policy_document" "eks-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name                = "${var.name}-eks-cluster-role"
  assume_role_policy  = data.aws_iam_policy_document.eks-assume-role-policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
}

resource "aws_eks_cluster" "main" {
  name     = var.name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.cluster_subnets
  }

  depends_on = [
    aws_iam_role.eks_cluster
  ]
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.id
}

data "tls_certificate" "main" {
  count = var.ingress_controller_serviceaccount != null ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  count           = var.ingress_controller_serviceaccount != null ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "ingress_controller_assume_role_policy" {
  count = var.ingress_controller_serviceaccount != null ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.main[0].url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:${var.ingress_controller_serviceaccount}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.main[0].arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ingress_controller_role" {
  count              = var.ingress_controller_serviceaccount != null ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.ingress_controller_assume_role_policy[0].json
  name               = "${var.name}-service-account-role"
}