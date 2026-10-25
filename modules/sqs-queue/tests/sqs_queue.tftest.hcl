mock_provider "aws" {}

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
