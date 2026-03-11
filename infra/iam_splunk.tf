# =============================================================================
# IAM User for Splunk Add-on for AWS
# =============================================================================
# Creates an IAM user with an access key and policies that allow read-only
# access to the CloudTrail, Config, and VPC Flow Logs S3 buckets. Use this
# user's access key and secret in the Splunk Add-on for AWS when adding an
# AWS account and configuring S3 inputs.
# =============================================================================

resource "aws_iam_user" "splunk" {
  count = var.create_splunk_iam_user ? 1 : 0

  name = "${var.project_name}-splunk-addon"
  path = "/"

  tags = {
    Name = "${var.project_name}-splunk-addon"
  }
}

# Allow Splunk to read CloudTrail log objects and list the bucket (always).
resource "aws_iam_user_policy" "splunk_cloudtrail" {
  count = var.create_splunk_iam_user ? 1 : 0

  name = "${var.project_name}-splunk-cloudtrail"
  user = aws_iam_user.splunk[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.cloudtrail.arn,
        "${aws_s3_bucket.cloudtrail.arn}/*"
      ]
    }]
  })
}

# Allow Splunk to read Config objects when AWS Config is enabled.
resource "aws_iam_user_policy" "splunk_config" {
  count = var.create_splunk_iam_user && var.enable_config ? 1 : 0

  name = "${var.project_name}-splunk-config"
  user = aws_iam_user.splunk[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.config[0].arn,
        "${aws_s3_bucket.config[0].arn}/*"
      ]
    }]
  })
}

# Allow Splunk to read VPC Flow Logs objects when VPC Flow Logs are enabled.
resource "aws_iam_user_policy" "splunk_vpcflow" {
  count = var.create_splunk_iam_user && var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.project_name}-splunk-vpcflow"
  user = aws_iam_user.splunk[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.vpc_flow_logs[0].arn,
        "${aws_s3_bucket.vpc_flow_logs[0].arn}/*"
      ]
    }]
  })
}

# Allow Splunk to consume SQS notifications for S3-based ingestion (optional).
resource "aws_iam_user_policy" "splunk_sqs" {
  count = var.create_splunk_iam_user && var.enable_sqs_s3_inputs ? 1 : 0

  name = "${var.project_name}-splunk-sqs"
  user = aws_iam_user.splunk[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ListQueues",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:ChangeMessageVisibility"
      ]
      Resource = "*"
    }]
  })
}

# Access key for the Splunk add-on. Secret is in terraform output (sensitive).
resource "aws_iam_access_key" "splunk" {
  count = var.create_splunk_iam_user ? 1 : 0

  user = aws_iam_user.splunk[0].name
}
