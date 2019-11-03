resource "aws_s3_bucket" "assets" {
  bucket_prefix = var.assets_bucket_prefix
  acl           = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expireDeletedAssets"
    enabled = true

    noncurrent_version_expiration {
      days = var.assets_bucket_noncurrent_version_expiration
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_public_access_block" "certs" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
