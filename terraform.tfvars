##############################################################
# terraform.tfvars  –  Override defaults here
# Copy this file and fill in your values.
##############################################################

aws_region   = "us-east-1"
project_name = "demo"

availability_zones  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

instance_type        = "t3.micro"
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2

# Tip: get the latest Amazon Linux 2023 AMI with:
# aws ec2 describe-images --owners amazon \
#   --filters 'Name=name,Values=al2023-ami-*-x86_64' \
#   --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
#   --output text
#ami_id = "ami-0f9098f7b7371ee94"
ami_id = "ami-02fe376e6ac9632c8"
