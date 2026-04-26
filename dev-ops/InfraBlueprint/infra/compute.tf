
# PART 2: COMPUTE — Security Group, IAM, AMI Lookup, EC2



# Data Source: Fetch latest Amazon Linux 2023 AMI
# No more hardcoding AMI IDs that go stale!

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# Security Group for Web Server (EC2)
# Controls what traffic is allowed in and out

resource "aws_security_group" "web" {
  name        = "vela-web-sg"
  description = "Allow HTTP, HTTPS from anywhere and SSH from admin IP only"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP (port 80) from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS (port 443) from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22) ONLY from your IP
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "vela-web-sg"
    Project = "vela-payments"
  }
}


# IAM Role — Lets EC2 assume a role (like a service account)

resource "aws_iam_role" "ec2_s3_role" {
  name = "vela-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = "vela-payments"
  }
}


# IAM Policy — Only GetObject and PutObject on our S3 bucket

resource "aws_iam_role_policy" "s3_access" {
  name = "vela-s3-access-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
    }]
  })
}


# IAM Instance Profile — Bridges the IAM role to EC2

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "vela-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name

  tags = {
    Project = "vela-payments"
  }
}


# EC2 Instance — The web server

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Vela Payments - Web Server</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name    = "vela-web-server"
    Project = "vela-payments"
  }
}
