


# S3 Bucket — Where our static assets live
# Must be globally unique across all of AWS!

resource "aws_s3_bucket" "assets" {
  bucket = var.s3_bucket_name

  tags = {
    Name    = "vela-assets-bucket"
    Project = "vela-payments"
  }
}


# S3 Bucket Versioning
# If someone accidentally overwrites or deletes a file,
# we can restore it from the hidden history.

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}


# S3 Public Access Block
# Security absolute: Prevents ANY public peering.
# Our EC2 IAM role will be the only allowed visitor.

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  # Block all external unauthenticated entry vectors
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
