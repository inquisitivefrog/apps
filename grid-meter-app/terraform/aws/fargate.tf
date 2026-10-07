# AWS Fargate for EKS — added 2026-10-06 to sidestep this account's hard SCP restriction on EC2
# instance types (only free-tier-eligible types like t4g.micro are allowed, and this app's real
# measured memory footprint - api alone needs a 1Gi limit, live-confirmed 2026-09-18 - doesn't fit
# on a 1GiB node once Kafka and the other pods are accounted for). Fargate allocates vCPU/memory
# directly per pod rather than launching a named EC2 instance type, so it may not be subject to
# the same SCP check at all - this is what we're testing live, not something confirmed to work yet.
#
# Deliberately NOT a full replacement for the existing EC2 node group (aws_eks_node_group.main in
# eks.tf) - EKS Fargate has a real, well-established limitation: it does not support EBS-backed
# PersistentVolumeClaims or StatefulSets at all (Fargate pods only get ephemeral storage, and the
# EBS CSI driver's node component is a DaemonSet, which Fargate also doesn't support). Kafka's
# StatefulSet (k8s/kafka.yaml) needs real EBS-backed disks for its 3 brokers, so it structurally
# cannot move to Fargate - it stays on the existing EC2 node group. This Fargate profile is scoped
# via a label selector (not just the namespace) specifically so Kafka's pods are excluded and
# continue scheduling onto the EC2 node group as before; only pods explicitly labeled
# `fargate: "true"` (intended: api, frontend, traefik - the stateless, memory-hungry-relative-to-
# node-size pods) match this profile.

# --- Fargate pod execution role ---
# Every Fargate profile needs one of these - it's the role AWS uses on your behalf to pull images
# and write logs for pods scheduled onto Fargate, analogous to the EC2 node IAM role but for
# Fargate capacity instead.
data "aws_iam_policy_document" "eks_fargate_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
    # Scoped to Fargate profiles on this specific cluster, not any EKS cluster in the account -
    # confirmed against AWS's own EKS Fargate pod-execution-role docs (2026-10-06): the real
    # required SourceArn pattern is a *fargateprofile* ARN (arn:...:fargateprofile/<cluster>/*),
    # not the cluster's own ARN - an easy, specific mistake to make since cluster.arn was readily
    # available and looked plausible, but AWS's CreateFargateProfile call rejected it outright
    # with "Misconfigured PodExecutionRole Trust Policy" until corrected.
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:fargateprofile/${local.cluster_name}/*"]
    }
  }
}

resource "aws_iam_role" "eks_fargate_pod_execution" {
  name               = "${var.project_name}-fargate-pod-execution-role"
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_policy" {
  role       = aws_iam_role.eks_fargate_pod_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# --- Fargate profile ---
# default namespace only, and only pods carrying the fargate=true label (added to
# api-aws.yaml/traefik-aws.yaml/frontend.yaml as a follow-up once this profile itself is
# confirmed to actually create - Kafka's manifest deliberately does NOT get this label, so it
# keeps scheduling onto the EC2 node group).
#
# Second selector added 2026-10-06: t3.micro's own EKS max-pods ceiling (an ENI/IP-count
# formula, confirmed live via a real FailedScheduling event - "3 Insufficient memory, 3 Too
# many pods") left zero scheduling room on any of the 3 EC2 nodes once the 3 mandatory
# daemonsets (kube-proxy, aws-node, ebs-csi-node - none of which can run on Fargate at all,
# same no-DaemonSet limitation noted above) plus one Kafka broker per node filled every
# available slot. ebs-csi-controller, coredns, and metrics-server don't need to be
# node-local like the daemonsets do, so routing just those to Fargate (via each addon's
# podLabels configuration_values, see eks.tf/ebs-csi.tf) frees the EC2 nodes for daemonsets +
# Kafka only - confirmed against each addon's real configurationSchema
# (`aws eks describe-addon-configuration`), not assumed to exist.
resource "aws_eks_fargate_profile" "default_ns_selected_pods" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${var.project_name}-default-selected"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "default"
    labels = {
      fargate = "true"
    }
  }

  selector {
    namespace = "kube-system"
    labels = {
      fargate = "true"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_fargate_pod_execution_policy,
    aws_eks_node_group.main,
  ]
}
