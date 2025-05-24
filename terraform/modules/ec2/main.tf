# Get the latest Ubuntu 22.04 LTS AMI dynamically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate SSH Key Pair for EC2
resource "tls_private_key" "k8s" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "k8s" {
  key_name   = var.key_name # Use variable instead of hardcoded name
  public_key = tls_private_key.k8s.public_key_openssh
}

# Save the private key locally
resource "local_file" "techkey" {
  content  = tls_private_key.k8s.private_key_pem
  filename = "${var.key_name}.pem" # Save the private key with dynamic filename
}


resource "aws_eip" "k8s_eip" {
  domain = "vpc" # Specifies that this is for use in a VPC
}

# EC2 Instance Configuration
resource "aws_instance" "gandalf" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  private_ip            = var.app_private_ip
  # secondary_private_ips = [var.grafana_private_ip]

  user_data = templatefile("${path.module}/minikube.sh", {
    IMAGE_TAG          = var.image_tag
    DOCKERHUB_USERNAME = var.dockerhub_user
  })

  tags = { Name = "gandalf" }
}

resource "aws_eip" "app" {
  instance                  = aws_instance.gandalf.id
  associate_with_private_ip = var.app_private_ip
  tags                      = { Name = "gandalf-app-eip" }
}
