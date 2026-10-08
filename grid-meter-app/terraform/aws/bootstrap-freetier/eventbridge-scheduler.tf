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
# TEST SCHEDULES ONLY for now (one-time `at(...)` expressions, near-term) - validating that
# EventBridge can actually replace GitHub's scheduler before committing to the permanent daily
# 11:00 UTC / 01:00 UTC cron times, per explicit plan (status/claude_code_2026-10-08.md).

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

# --- IAM role EventBridge Scheduler assumes to invoke the API Destinations ---
resource "aws_iam_role" "scheduler_exec" {
  name = "${var.project_name}-eventbridge-scheduler-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_api_destinations" {
  name = "${var.project_name}-invoke-github-dispatch"
  role = aws_iam_role.scheduler_exec.id

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

# --- One-time TEST schedules (near-term, UTC) - see header comment ---
# Both post {"ref":"main"} as the request body, matching exactly what `gh workflow run
# <workflow> --ref main` sends - the same manual trigger used successfully all session.
resource "aws_scheduler_schedule" "test_startup" {
  name                         = "${var.project_name}-test-startup-once"
  schedule_expression          = "at(2026-10-08T20:05:00)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_cloudwatch_event_api_destination.startup.arn
    role_arn = aws_iam_role.scheduler_exec.arn
    input    = jsonencode({ ref = "main" })
  }
}

resource "aws_scheduler_schedule" "test_teardown" {
  name                         = "${var.project_name}-test-teardown-once"
  schedule_expression          = "at(2026-10-08T20:55:00)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_cloudwatch_event_api_destination.teardown.arn
    role_arn = aws_iam_role.scheduler_exec.arn
    input    = jsonencode({ ref = "main" })
  }
}
