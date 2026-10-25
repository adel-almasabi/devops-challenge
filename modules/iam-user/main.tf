resource "aws_iam_user" "this" {
  name = var.name

  tags = var.tags
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

data "aws_iam_policy_document" "bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }
}

resource "aws_iam_user_policy" "bucket" {
  name   = "${var.name}-bucket"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.bucket.json
}
