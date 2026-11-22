output "queue_name" {
  value = aws_sqs_queue.this.name
}

output "queue_url" {
  value = aws_sqs_queue.this.url
}

output "queue_arn" {
  value = aws_sqs_queue.this.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}

output "alarm_topic_arn" {
  description = "SNS topic that receives the alarm notifications, or null when alarm_email is empty."
  value       = one(aws_sns_topic.alarms[*].arn)
}
