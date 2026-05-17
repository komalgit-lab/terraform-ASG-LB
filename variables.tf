##############################################################
# variables.tf  –  Root input variables
##############################################################

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix applied to every resource name"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to spread subnets/instances across (min 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR per AZ for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# ── EC2 / AMI ─────────────────────────────────────────────
variable "ami_id" {
  description = "Amazon Linux 2023 AMI (us-east-1). Run: aws ec2 describe-images --owners amazon --filters 'Name=name,Values=al2023-ami-*-x86_64' --query 'Images[0].ImageId'"
  type        = string
  default     = "ami-0c02fb55956c7d316"   # Amazon Linux 2023 us-east-1 (update if needed)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# ── ASG sizing ────────────────────────────────────────────
variable "asg_min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances at launch"
  type        = number
  default     = 2
}
