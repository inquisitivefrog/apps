# AWS Load Balancer Controller - added 2026-10-07 specifically to get a STABLE public address
# for the demo (a resume-facing URL businesses may not look at for a week+, so it can't change
# daily the way the in-tree Classic ELB provider's auto-generated hostname does - confirmed live
# this session that AWS never lets you reuse or pin a Classic ELB hostname across recreations).
#
# The in-tree AWS cloud provider (what every prior version of traefik-aws.yaml relied on, with no
# controller installed) cannot assign a static Elastic IP to a load balancer at all - that
# capability (the aws-load-balancer-eip-allocations Service annotation) is specifically a feature
# of this controller, confirmed against its own docs
# (kubernetes-sigs.github.io/aws-load-balancer-controller), not assumed.
#
# Installed via Helm in k8s/deploy-aws.sh (matching this project's existing pattern for
# Helm-managed pieces, e.g. k8s/deploy-observability.sh's kube-prometheus-stack), not as an
# aws_eks_addon - AWS does not offer this controller as an EKS-managed addon type the way
# vpc-cni/coredns/kube-proxy/metrics-server/ebs-csi-driver are.
#
# No IRSA: this account has the same hard SCP block on iam:CreateOpenIDConnectProvider that
# already forced ebs-csi.tf and elasticache-iam-auth.tf off IRSA. Same workaround reused here -
# the controller's required IAM policy (aws-load-balancer-controller-iam-policy.json, fetched
# verbatim from the controller's own GitHub repo, main branch, 2026-10-07 - re-verify if this
# project's controller version is ever pinned rather than tracking :latest) is granted directly to
# the existing EC2 node role instead. The controller's pods must land on the EC2 node group, not
# Fargate, to actually get these permissions via IMDS (same constraint already documented in
# ebs-csi.tf) - they will by default, since k8s/deploy-aws.sh's Helm install does not apply the
# fargate=true label the Fargate profile's selector requires.
resource "aws_iam_policy" "lb_controller" {
  name   = "${var.project_name}-lb-controller"
  policy = file("${path.module}/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller_on_node_role" {
  role       = aws_iam_role.eks_node.name
  policy_arn = aws_iam_policy.lb_controller.arn
}
