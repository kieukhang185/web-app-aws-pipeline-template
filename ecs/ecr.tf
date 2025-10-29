# Terraform ECR Repository
resource "aws_ecr_repository" "app" {
  name = var.app_name
  image_scanning_configuration { scan_on_push = true }
  force_delete = true

  tags = merge(local.tags, {
    Name = "${var.app_name}-ecr"
  })
}
