# Without the EBS CSI driver installed, no StorageClass - default or not - can actually
# provision real storage on EKS. A vanilla EKS cluster (created via the API/Terraform, not
# through the older eksctl-with-in-tree-provisioner path) does not install this by default; it's
# an opt-in addon, same as vpc-cni/coredns/kube-proxy in eks.tf, just needing its own IAM
# permissions via IRSA (IAM Roles for Service Accounts) since it has to call the EC2 API to
# create/attach/detach real EBS volumes.

# The OIDC issuer certificate's thumbprint is fetched live rather than hardcoded - AWS has
# rotated the underlying CA before, which broke every hardcoded thumbprint anyone had pinned.
# This stays correct automatically if that ever happens again.
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    # Scoped to exactly the one service account the EBS CSI driver addon runs
    # as - not a blanket trust of anything in the cluster.
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.project_name}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role = aws_iam_role.ebs_csi_driver.name
  # Verified live via `aws iam list-policies` (2026-09-17) - the standard,
  # broadly-documented managed policy for this purpose. AWS also offers
  # newer V2/cluster-scoped variants; not adopted here without a specific
  # reason to need their narrower/different permission model.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
  ]
}
