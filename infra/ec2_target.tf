# -----------------------------------------------------------------------------
# Optional EC2 instance to serve as a Stratus target
# -----------------------------------------------------------------------------
# Several Stratus Red Team techniques expect an EC2 instance to exist so they
# can perform actions such as stopping, rebooting, or manipulating tags.
# This optional resource provisions a minimal Amazon Linux instance in the
# default VPC along with the supporting security group and role.
# -----------------------------------------------------------------------------

data "aws_ami" "stratus_target" {
  count = var.create_stratus_target_instance ? 1 : 0

  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "stratus_target" {
  count   = var.create_stratus_target_instance ? 1 : 0
  default = true
}

data "aws_subnets" "stratus_target" {
  count = var.create_stratus_target_instance ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.stratus_target[0].id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "stratus_target" {
  count = var.create_stratus_target_instance ? 1 : 0

  name        = "${var.project_name}-stratus-target"
  description = "Minimal SG for Stratus target instance"
  vpc_id      = data.aws_vpc.stratus_target[0].id

  egress {
    description = "Allow all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = length(var.stratus_target_allowed_ssh_cidrs) > 0 ? var.stratus_target_allowed_ssh_cidrs : []
    content {
      description = "Allowed SSH CIDR"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = [ingress.value]
    }
  }

  tags = {
    Name = "${var.project_name}-stratus-target"
  }
}

resource "aws_iam_role" "stratus_target" {
  count = var.create_stratus_target_instance ? 1 : 0

  name = "${var.project_name}-stratus-target"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "stratus_target_ssm" {
  count      = var.create_stratus_target_instance ? 1 : 0
  role       = aws_iam_role.stratus_target[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "stratus_target" {
  count = var.create_stratus_target_instance ? 1 : 0

  name = "${var.project_name}-stratus-target"
  role = aws_iam_role.stratus_target[0].name
}

resource "aws_instance" "stratus_target" {
  count = var.create_stratus_target_instance ? 1 : 0

  ami                         = data.aws_ami.stratus_target[0].id
  instance_type               = var.stratus_target_instance_type
  subnet_id                   = data.aws_subnets.stratus_target[0].ids[0]
  vpc_security_group_ids      = [aws_security_group.stratus_target[0].id]
  iam_instance_profile        = aws_iam_instance_profile.stratus_target[0].name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.project_name}-stratus-target"
    Role = "stratus-target"
  }
}

output "stratus_target_instance_id" {
  description = "Instance ID of the optional Stratus target EC2 instance."
  value       = var.create_stratus_target_instance ? aws_instance.stratus_target[0].id : null
}

output "stratus_target_public_ip" {
  description = "Public IP (if any) of the Stratus target EC2 instance."
  value       = var.create_stratus_target_instance ? aws_instance.stratus_target[0].public_ip : null
}
