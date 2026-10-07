# Without the EBS CSI driver installed, no StorageClass - default or not - can actually
# provision real storage on EKS. A vanilla EKS cluster (created via the API/Terraform, not
# through the older eksctl-with-in-tree-provisioner path) does not install this by default; it's
# an opt-in addon, same as vpc-cni/coredns/kube-proxy in eks.tf.
#
# Originally wired via IRSA (IAM Roles for Service Accounts) - a dedicated role trusted only by
# the driver's own ServiceAccount, via OIDC federation. Reverted 2026-10-06 to the older,
# pre-IRSA pattern (permissions granted directly to the EC2 node group's own IAM role instead)
# after confirming live that this account (184375956348, the free-tier/credits-program account)
# has a hard AWS Organizations SCP explicit-denying iam:CreateOpenIDConnectProvider outright -
# not a permissions gap fixable by policy, a wall. No OIDC provider means no IRSA at all is
# possible on this account, for anything, ever - see fargate.tf's and elasticache-iam-auth.tf's
# own comments for the other two things this same constraint forced a design change on.
# Less precise than IRSA (every pod on the node could theoretically use these permissions, not
# just the CSI driver's own pod), but this is exactly the standard, fully-supported mechanism
# EBS CSI used before IRSA existed, not a hack - see eks.tf's aws_iam_role_policy_attachment.
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver_on_node_role,
  ]
}
