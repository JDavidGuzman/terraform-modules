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
  name     = "${var.name}-eks-cluster"
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