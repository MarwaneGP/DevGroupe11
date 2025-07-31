# Generate random suffix for bucket name
resource "random_integer" "random" {
  min = 1
  max = 50000
}

# S3 bucket for hosting static website
resource "aws_s3_bucket" "main" {
  bucket = "${local.actual_bucket_name}-${random_integer.random.result}"
  tags   = var.tags
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket policy for public access
resource "aws_s3_bucket_policy" "allow_content_public" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.allow_content_public.json
}

# IAM policy document for S3 public access
data "aws_iam_policy_document" "allow_content_public" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}

# Upload built files to S3
resource "aws_s3_object" "sync_remote_website_content" {
  # ✅ CORRECTION : utilise local.build_path qui s'adapte à l'environnement
  for_each = fileset(local.build_path, "**/*.*")

  bucket = aws_s3_bucket.main.id
  key    = each.value
  source = "${local.build_path}/${each.value}"
  etag   = filemd5("${local.build_path}/${each.value}")

  content_type = try(
    lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1]),
    "binary/octet-stream"
  )
}