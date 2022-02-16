data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_main_node_group" {
  name               = "${var.name}-eks-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name}-eks-main-node-group"
  node_role_arn   = aws_iam_role.eks_main_node_group.arn
  subnet_ids      = [for i, s in var.cluster_subnets : s if i % 2 != 0]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable = 2
  }

  instance_types = var.instance_type

  labels = {
    role = "main-node-group"
  }

  depends_on = [
    aws_iam_role.eks_main_node_group
  ]
}