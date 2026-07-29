variable "cluster_name" { type = string }
variable "environment" { type = string }
variable "oidc_provider_arn" { type = string }

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = {
    Name        = "${var.cluster_name}-node-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_registry" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "irsa" {
  name               = "${var.cluster_name}-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json

  tags = {
    Name        = "${var.cluster_name}-irsa-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "ebs_csi" {
  name        = "${var.cluster_name}-ebs-csi-policy"
  description = "Policy for EBS CSI driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:volume/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:snapshot/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "irsa_ebs_csi" {
  policy_arn = aws_iam_policy.ebs_csi.arn
  role       = aws_iam_role.irsa.name
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "irsa_role_arn" {
  value = aws_iam_role.irsa.arn
}
