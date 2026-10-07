# A static public address for the demo's resume-facing URL - added 2026-10-07 after the user
# pointed out businesses reviewing a resume may not look at it for a week+, so the URL can't
# change daily the way the AWS Load Balancer Controller's NLB hostname (or the original in-tree
# Classic ELB's) would on its own. An Elastic IP is what actually stays fixed across every nightly
# destroy/rebuild of ../ (the main stack) - confirmed via AWS's own EIP semantics: the allocation
# itself is independent of whatever load balancer it's currently associated with, so it survives
# that resource being deleted and recreated, same reasoning already applied to ecr.tf living here
# instead of in the nightly-destroyed stack.
#
# One EIP only, deliberately - the aws-load-balancer-eip-allocations annotation requires exactly
# one EIP per subnet the NLB uses, and this project's edge tier is already explicitly single-AZ
# (see docs/ha-scope.md), so a single EIP/single-subnet NLB matches a decision already made, not
# a new compromise. See ../outputs.tf's nlb_subnet_id output for the matching single subnet.
resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-app"
  }
}
