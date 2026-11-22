resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = var.tags
}

resource "aws_sqs_queue" "this" {
  name                       = var.name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "oldest_message_age" {
  alarm_name        = "${var.name}-oldest-message-age"
  alarm_description = "Messages in ${var.name} are not being consumed"

  namespace   = "AWS/SQS"
  metric_name = "ApproximateAgeOfOldestMessage"
  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 3
  threshold           = var.alarm_age_threshold_seconds
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

# Optional notification path: set alarm_email to get an email when the alarm fires and when it recovers.
# SNS sends a confirmation mail first. Nothing is delivered until the recipient clicks the link.
# The topic is not encrypted: CloudWatch alarms cannot publish to a topic that uses the AWS managed key,
# and the messages only carry the alarm name and state.
data "aws_caller_identity" "current" {
  count = local.create_topic ? 1 : 0
}

data "aws_region" "current" {
  count = local.create_topic ? 1 : 0
}

locals {
  create_topic  = var.alarm_email != ""
  alarm_actions = concat(var.alarm_actions, aws_sns_topic.alarms[*].arn)
}

resource "aws_sns_topic" "alarms" {
  count = local.create_topic ? 1 : 0

  name = "${var.name}-alarms"
  tags = var.tags
}

resource "aws_sns_topic_policy" "alarms" {
  count = local.create_topic ? 1 : 0

  arn = aws_sns_topic.alarms[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchAlarmsInThisAccount"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alarms[0].arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current[0].account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:cloudwatch:${data.aws_region.current[0].name}:${data.aws_caller_identity.current[0].account_id}:alarm:*" }
        }
      },
    ]
  })
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count = local.create_topic ? 1 : 0

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
