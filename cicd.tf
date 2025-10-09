# ==========================================
# CI/CD PIPELINE WITH PM2
# ==========================================

# ==========================================
# CODEBUILD - Builds your Go app
# ==========================================

resource "aws_codebuild_project" "app" {
  name          = "${var.project_name}-build"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      
      phases:
        build:
          commands:
            - echo "Building main Go application..."
            - go build -o app .
            - chmod +x app
            - echo "Building background worker..."
            - go build -o worker ./cmd/worker
            - chmod +x worker
      
      artifacts:
        files:
          - app
          - worker
          - ecosystem.config.js
          - appspec.yml
          - scripts/**/*
    EOF
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  tags = local.common_tags
}

# ==========================================
# CODEDEPLOY - Deploys to EC2
# ==========================================

resource "aws_codedeploy_app" "app" {
  name             = var.project_name
  compute_platform = "Server"
  tags             = local.common_tags
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${var.project_name}-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      type  = "KEY_AND_VALUE"
      key   = "Name"
      value = "${var.project_name}-instance"
    }
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  tags = local.common_tags
}

# ==========================================
# CODEPIPELINE - Automates everything
# ==========================================

resource "aws_codepipeline" "app" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  # Stage 1: Get code from GitHub
  stage {
    name = "Source"

    action {
      name             = "GetSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_code"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  # Stage 2: Build the Go app
  stage {
    name = "Build"

    action {
      name             = "BuildApp"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_code"]
      output_artifacts = ["built_app"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  # Stage 3: Deploy to EC2
  stage {
    name = "Deploy"

    action {
      name            = "DeployToEC2"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["built_app"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.app.deployment_group_name
      }
    }
  }

  tags = local.common_tags
}