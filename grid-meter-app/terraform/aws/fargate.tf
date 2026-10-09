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
# `fargate: "true"` (api, frontend - the stateless, memory-hungry-relative-to-node-size pods)
# match this profile. traefik moved to its own dedicated, single-AZ profile below
# (aws_eks_fargate_profile.traefik_single_az) on 2026-10-09 - see that resource's own comment
# for why it can't share this one.

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

# --- Dedicated single-AZ Fargate profile for traefik only ---
# The NLB (traefik-aws.yaml's Service) is deliberately pinned to a single AZ/subnet (us-east-2a,
# aws_subnet.public[0] - matching eip.tf's single persistent EIP) - an NLB can only route to
# targets inside its own enabled AZs. The broad profile above spans all 3 AZs
# (aws_subnet.private[*]), so if the traefik pod itself ever lands on a Fargate node outside
# us-east-2a, the NLB's target shows up as State: "unused" / "Target.NotInUse" / "Target is in an
# Availability Zone that is not enabled for the load balancer" - a complete, silent public outage
# despite every kubectl-level health check passing cleanly. Confirmed live 2026-10-09: the
# EventBridge-triggered morning run deployed cleanly (every pod Ready, all CI checks green up to
# this point), but Fargate happened to schedule traefik into us-east-2b, and the app was 100%
# unreachable - a TCP SYN timeout, not an HTTP error, confirmed via curl/nc/ping all independently
# - for over 5 hours until caught manually, because the "End-to-end login health check" step's
# single curl attempt had no retry and only ran once, early in the run.
#
# This profile exists specifically to make that scheduling outcome impossible: only the traefik
# pod (carrying its own distinct `fargate-single-az: "true"` label, deliberately NOT the shared
# `fargate: "true"` the broad profile above matches) is scheduled here, restricted to the one
# private subnet in the same AZ as the NLB. Kept as a separate profile rather than just narrowing
# the broad one's subnet_ids, since AWS's own docs state pod-to-profile matching is undefined when
# a pod could satisfy more than one Fargate profile's selector - giving traefik a distinct label
# key (not just reusing fargate=true) avoids that ambiguity entirely, rather than relying on
# profile evaluation order.
resource "aws_eks_fargate_profile" "traefik_single_az" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${var.project_name}-traefik-single-az"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution.arn
  subnet_ids             = [aws_subnet.private[0].id] # us-east-2a - confirmed live via `terraform state show`, must match the NLB's enabled AZ

  selector {
    namespace = "default"
    labels = {
      "fargate-single-az" = "true"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_fargate_pod_execution_policy,
    aws_eks_node_group.main,
  ]
}
