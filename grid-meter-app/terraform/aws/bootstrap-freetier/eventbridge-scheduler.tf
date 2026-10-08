# Replaces GitHub Actions' own `schedule:` cron trigger, which has shown a consistent,
# repeatable ~6-7hr dispatch lag on this repo (confirmed 2026-10-08 against weeks of
# grid-meter-app-load-test.yml history, and reproduced live on both the startup and teardown
# workflows the same day) - a documented, widely-reported GitHub Actions platform characteristic
# (best-effort delivery, no guaranteed execution window - see the GitHub community discussion
# linked in status/claude_code_2026-10-08.md), not something fixable from this repo's side.
#
# EventBridge Scheduler calls GitHub's REST API (POST .../actions/workflows/<file>/dispatches)
# directly via an API Destination - every `workflow_dispatch` run triggered manually this session
# started within seconds, so moving dispatch onto AWS's own scheduler (not this Mac, which can't
# be guaranteed always-on) sidesteps GitHub's scheduler entirely rather than working around it.
#
# Lives in bootstrap-freetier/ (the persistent layer, same reasoning as eip.tf/ecr.tf) because
# its whole job is to trigger the main stack's own nightly create/destroy cycle - it must not be
# destroyed alongside what it's scheduling.
#
# Validated 2026-10-08 via two one-time near-term test rules before committing to these permanent
# daily times: both fired within ~20 seconds of their scheduled time (20:10:17 vs 20:10:00 for
# startup, 21:00:15 vs 21:00:00 for teardown), and the startup test was also the first-ever fully
# green run of the complete pipeline with every 2026-10-08 fix in place. Converted to the real
# daily schedule below (11:00 UTC / 4am PDT startup, 01:00 UTC / 6pm PDT teardown) immediately
# after - see status/claude_code_2026-10-08.md for the full validation account.

variable "github_pat" {
  description = "Fine-grained GitHub PAT, repo-scoped to inquisitivefrog/apps with Actions: Read and write only. Never set a default - pass via TF_VAR_github_pat in the shell running `terraform apply`, never committed or pasted into chat."
  type        = string
  sensitive   = true
}

variable "github_repo_owner" {
  description = "GitHub org/user owning the target repo."
  type        = string
  default     = "inquisitivefrog"
}

variable "github_repo_name" {
  description = "GitHub repo containing the workflows to dispatch."
  type        = string
  default     = "apps"
}

# --- Connection: holds the GitHub PAT, shared by both API Destinations below ---
resource "aws_cloudwatch_event_connection" "github_api" {
  name               = "${var.project_name}-github-api"
  description        = "Auth for calling GitHub's REST API to dispatch grid-meter-app's AWS workflows."
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "Authorization"
      value = "Bearer ${var.github_pat}"
    }
  }
}

# --- API Destinations: one per workflow, since each has its own fixed dispatch URL ---
resource "aws_cloudwatch_event_api_destination" "startup" {
  name                             = "${var.project_name}-aws-startup-dispatch"
  description                      = "Dispatches grid-meter-app-aws-startup.yml via GitHub's REST API."
  invocation_endpoint              = "https://api.github.com/repos/${var.github_repo_owner}/${var.github_repo_name}/actions/workflows/grid-meter-app-aws-startup.yml/dispatches"
  http_method                      = "POST"
  invocation_rate_limit_per_second = 1
  connection_arn                   = aws_cloudwatch_event_connection.github_api.arn
}

resource "aws_cloudwatch_event_api_destination" "teardown" {
  name                             = "${var.project_name}-aws-teardown-dispatch"
  description                      = "Dispatches grid-meter-app-aws-teardown.yml via GitHub's REST API."
  invocation_endpoint              = "https://api.github.com/repos/${var.github_repo_owner}/${var.github_repo_name}/actions/workflows/grid-meter-app-aws-teardown.yml/dispatches"
  http_method                      = "POST"
  invocation_rate_limit_per_second = 1
  connection_arn                   = aws_cloudwatch_event_connection.github_api.arn
}

# --- IAM role EventBridge Rules assumes to invoke the API Destinations ---
# NOT EventBridge *Scheduler* (scheduler.amazonaws.com) - confirmed live (2026-10-08) via a real
# failed apply that Scheduler's `aws_scheduler_schedule` does NOT support API Destinations as a
# target at all (only "templated" targets like SQS/Lambda/Step Functions, or "universal" targets
# that call an AWS service API directly - a third-party HTTPS endpoint is neither). API
# Destinations are a feature of the older EventBridge Rules service instead
# (`aws_cloudwatch_event_rule`/`aws_cloudwatch_event_target`), confirmed against AWS's own docs,
# which supports them natively. Rules don't have Scheduler's one-time `at(...)` expression though
# - only `cron(...)`/`rate(...)` - so the near-term tests below use a cron expression pinned to a
# specific date/time, which only ever matches once by construction.
resource "aws_iam_role" "events_exec" {
  name = "${var.project_name}-eventbridge-rules-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "events_invoke_api_destinations" {
  name = "${var.project_name}-invoke-github-dispatch"
  role = aws_iam_role.events_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "events:InvokeApiDestination"
      Resource = [
        aws_cloudwatch_event_api_destination.startup.arn,
        aws_cloudwatch_event_api_destination.teardown.arn,
      ]
    }]
  })
}

# --- Permanent daily rules (UTC) ---
# cron(minutes hours day-of-month month day-of-week year) - `?` required in exactly one of
# day-of-month/day-of-week, `*` in the other, matching AWS's own documented daily-rule pattern.
# Both targets post {"ref":"main"}, matching exactly what `gh workflow run <workflow> --ref main`
# sends - the same manual trigger used successfully all session.
#
# Cron caveat (carried over from grid-meter-app-aws-startup.yml's own header comment): these are
# UTC-only, no timezone/DST awareness. 11:00 UTC is 4:00am PDT (daylight) but 3:00am PST (standard
# time) - this will fire an hour earlier than intended for roughly half the year. Re-check if
# interviews are ever scheduled during PST months and the buffer before 5am matters.
resource "aws_cloudwatch_event_rule" "daily_startup" {
  name                = "${var.project_name}-daily-startup"
  description         = "Daily cold-start of the AWS free-tier demo deployment, 11:00 UTC / ~4am PDT."
  schedule_expression = "cron(0 11 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_startup" {
  rule     = aws_cloudwatch_event_rule.daily_startup.name
  arn      = aws_cloudwatch_event_api_destination.startup.arn
  role_arn = aws_iam_role.events_exec.arn
  input    = jsonencode({ ref = "main" })
}

resource "aws_cloudwatch_event_rule" "daily_teardown" {
  name                = "${var.project_name}-daily-teardown"
  description         = "Daily teardown of the AWS free-tier demo deployment, 01:00 UTC / ~6pm PDT the evening before."
  schedule_expression = "cron(0 1 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_teardown" {
  rule     = aws_cloudwatch_event_rule.daily_teardown.name
  arn      = aws_cloudwatch_event_api_destination.teardown.arn
  role_arn = aws_iam_role.events_exec.arn
  input    = jsonencode({ ref = "main" })
}
