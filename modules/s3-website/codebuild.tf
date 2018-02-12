# Load configuration files from template

data "template_file" "codebuild-policy" {
  template = "${file("${path.module}/iam/codebuild-policy.tmpl")}"

  vars {
    bucket_name = "${aws_s3_bucket.prod_bucket.id}"
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-role-release-blog"
  assume_role_policy = "${file("${path.module}/iam/codebuild-role.txt")}"
}

# IAM configuration

resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"
  policy      = "${data.template_file.codebuild-policy.rendered}"
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles      = ["${aws_iam_role.codebuild_role.id}"]
}

# Create CodeBuild job

resource "aws_codebuild_project" "codebuild-project" {
  name          = "${var.service_name}"
  description   = "${var.description}"
  build_timeout = "15"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.container}"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "GITHUB"
    location  = "${var.source_repository}"
    buildspec = "${var.buildspec}"
  }
}