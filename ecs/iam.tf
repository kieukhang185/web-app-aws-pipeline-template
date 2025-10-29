
# Terraform IAM Role for ECS Task Execution with ECS Exec
data "aws_iam_policy_document" "ecs_exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.app_name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Terraform IAM Role for CodeBuild with ECR Push Permissions
data "aws_iam_policy_document" "cb_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.app_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.cb_assume.json
}

resource "aws_iam_role_policy_attachment" "cb_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy" "cb_logs" {
  name = "${var.app_name}-codebuild-logs"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource : [
          aws_cloudwatch_log_group.app.arn,
          "${aws_cloudwatch_log_group.app.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "cb_s3_attach" {
  name = "${var.app_name}-codebuild-s3"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      }
    ]
  })
}

# Terraform IAM Role for CodePipeline
data "aws_iam_policy_document" "cp_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.app_name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.cp_assume.json
}

resource "aws_iam_role_policy_attachment" "cp_full" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy" "cp_use_connection" {
  name = "${var.app_name}-cp-use-connection"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "cp_artifacts_s3" {
  name = "${var.app_name}-cp-artifacts-s3"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Bucket-level
      {
        Effect : "Allow",
        Action : [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ],
        Resource : aws_s3_bucket.artifacts.arn
      },
      {
        Effect : "Allow",
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObjectVersion",
          "s3:GetObjectAcl"
        ],
        Resource : "${aws_s3_bucket.artifacts.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cp_codebuild" {
  name = "${var.app_name}-cp-codebuild"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow the pipeline to start project
      {
        Effect : "Allow",
        Action : [
          "codebuild:StartBuild"
        ],
        Resource : "${aws_codebuild_project.app_build.arn}"
      },
      {
        Effect : "Allow",
        Action : [
          "codebuild:BatchGetProjects",
          "codebuild:BatchGetBuilds",
          "codebuild:ListBuildsForProject"
        ],
        Resource : "*"
      }
    ]
  })
}

# Deployment IAM Role for CodePipeline to deploy to ECS
resource "aws_iam_role_policy" "cp_codedeploy_ecs" {
  name = "${var.app_name}-cp-codedeploy-ecs"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:List*",
          "codedeploy:Batch*"
        ],
        Resource = "*"
      },
      # ECS reads still needed if your pipeline also inspects/updates ECS
      {
        Effect: "Allow",
        Action: [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTaskSets",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ],
        Resource: "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          aws_iam_role.ecs_task_execution.arn
        ]
      }
    ]
  })
}
