// ECR Repository for Docker images
resource "aws_ecr_repository" "client" {
  name                 = "${var.project_name}-client"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}