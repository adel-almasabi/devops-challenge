mock_provider "aws" {
  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:ap-southeast-3:111111111111:test-queue-alarms"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "ap-southeast-3"
    }
  }
}

variables {
  name = "test-queue"
}

run "creates_queue_and_dlq" {
  command = apply

  assert {
    condition     = aws_sqs_queue.this.name == "test-queue"
    error_message = "Queue should use the given name"
  }

  assert {
    condition     = aws_sqs_queue.dlq.name == "test-queue-dlq"
    error_message = "Dead-letter queue should be named <name>-dlq"
  }
}

run "redrive_uses_max_receive_count" {
  command = apply

  variables {
    max_receive_count = 3
  }

  assert {
    condition     = jsondecode(aws_sqs_queue.this.redrive_policy).maxReceiveCount == 3
    error_message = "Redrive policy should use max_receive_count"
  }
}

run "no_email_means_no_topic" {
  command = apply

  assert {
    condition     = length(aws_sns_topic.alarms) == 0
    error_message = "No topic should be created when alarm_email is empty"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.oldest_message_age.alarm_actions) == 0
    error_message = "The alarm should have no actions when nothing is configured"
  }
}

run "email_creates_topic_and_connects_the_alarm" {
  command = apply

  variables {
    alarm_email = "oncall@example.invalid"
  }

  assert {
    condition     = aws_sns_topic_subscription.alarm_email[0].protocol == "email" && aws_sns_topic_subscription.alarm_email[0].endpoint == "oncall@example.invalid"
    error_message = "The topic should send to the given email address"
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.oldest_message_age.alarm_actions, aws_sns_topic.alarms[0].arn)
    error_message = "The alarm should notify the topic when it fires"
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.oldest_message_age.ok_actions, aws_sns_topic.alarms[0].arn)
    error_message = "The alarm should notify the topic when it recovers"
  }
}

run "topic_policy_only_allows_cloudwatch_in_this_account" {
  command = apply

  variables {
    alarm_email = "oncall@example.invalid"
  }

  assert {
    condition     = jsondecode(aws_sns_topic_policy.alarms[0].policy).Statement[0].Principal.Service == "cloudwatch.amazonaws.com"
    error_message = "Only CloudWatch should be allowed to publish"
  }
}

run "extra_alarm_actions_are_kept" {
  command = apply

  variables {
    alarm_email   = "oncall@example.invalid"
    alarm_actions = ["arn:aws:sns:ap-southeast-3:111111111111:other"]
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.oldest_message_age.alarm_actions) == 2
    error_message = "Given alarm_actions should be kept next to the email topic"
  }
}
