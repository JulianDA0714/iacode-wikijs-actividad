data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}


resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid = "ReadWikiDatabaseSecret"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.postgres_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "secrets_access" {
  name   = "${var.project_name}-secrets-access"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.secrets_access.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}


resource "aws_instance" "wikijs" {

  depends_on = [
    aws_iam_role_policy.secrets_access,
    aws_iam_role_policy_attachment.ssm
  ]

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    postgres_secret_arn = var.postgres_secret_arn
    aws_region          = "us-east-2"
    postgres_endpoint   = var.postgres_endpoint
    redis_endpoint      = var.redis_endpoint
  })

  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.ec2_security_group_id]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 16
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name     = "${var.project_name}-ec2"
    Activity = "Actividad6"
  }
}
