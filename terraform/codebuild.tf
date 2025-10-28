
resource "aws_codebuild_project" "app_build" {
  name          = "${var.app_name}-build"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # CodeBuild w/ Docker needs this to build images

    environment_variable {
      name  = "ECR_REPO_URI"
      value = aws_ecr_repository.app.repository_url
    }
  }

  source { type = "CODEPIPELINE" }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.app.name
    }
  }

  tags = merge(local.tags, {
    Name = "${var.app_name}-codebuild"
  })
}
