# -----------------------------
# Key Pair
# -----------------------------
resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key-${var.env}"
  public_key = file("${path.module}/../../devops-key.pub")
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "sg" {
  name = "devops-sg-${var.env}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "devops-${var.env}"
  }
}
