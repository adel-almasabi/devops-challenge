mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::test-bucket"
    }
  }
}

variables {
  name = "test-bucket"
}

run "defaults_are_private" {
  command = apply

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this[0].block_public_acls,
      aws_s3_bucket_public_access_block.this[0].block_public_policy,
      aws_s3_bucket_public_access_block.this[0].ignore_public_acls,
      aws_s3_bucket_public_access_block.this[0].restrict_public_buckets,
    ])
    error_message = "All four public access blocks should be on by default"
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs should be disabled"
  }
}

run "defaults_do_not_allow_deleting_data" {
  command = apply

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy should be off by default"
  }
}

run "https_is_required" {
  command = apply

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.tls_only[0].policy).Statement[0].Effect == "Deny"
    error_message = "Requests without HTTPS should be denied"
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.tls_only[0].policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "The deny should apply when SecureTransport is false"
  }
}

run "unfinished_uploads_are_cleaned_up_by_default" {
  command = apply

  assert {
    condition     = length([for r in aws_s3_bucket_lifecycle_configuration.this[0].rule : r if r.id == "abort-incomplete-multipart-uploads"]) == 1
    error_message = "Incomplete multipart uploads should be aborted by default"
  }
}

run "old_versions_expire_when_versioning_is_on" {
  command = apply

  variables {
    versioning                         = true
    noncurrent_version_expiration_days = 14
  }

  assert {
    condition     = length([for r in aws_s3_bucket_lifecycle_configuration.this[0].rule : r if r.id == "expire-old-versions"]) == 1
    error_message = "Old versions should expire when versioning is on"
  }
}

run "no_old_version_rule_without_versioning" {
  command = apply

  assert {
    condition     = length([for r in aws_s3_bucket_lifecycle_configuration.this[0].rule : r if r.id == "expire-old-versions"]) == 0
    error_message = "There is nothing to expire when versioning is off"
  }
}

run "expiration_rules_are_kept" {
  command = apply

  variables {
    lifecycle_rules = [{ id = "expire-test-files", prefix = "", expiration_days = 30 }]
  }

  assert {
    condition     = length([for r in aws_s3_bucket_lifecycle_configuration.this[0].rule : r if r.id == "expire-test-files"]) == 1
    error_message = "A given expiration rule should be kept"
  }
}

run "protections_can_be_turned_off" {
  command = apply

  variables {
    block_public_access = false
    enforce_tls         = false
  }

  assert {
    condition     = length(aws_s3_bucket_public_access_block.this) == 0 && length(aws_s3_bucket_policy.tls_only) == 0
    error_message = "Turning the options off should remove the resources"
  }
}
