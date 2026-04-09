variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami" {
  description = "AMI ID"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}
