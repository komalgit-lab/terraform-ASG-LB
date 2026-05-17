##############################################################
# modules/asg/main.tf
# Creates: EC2 Security Group, Launch Template, Auto Scaling Group
##############################################################

# ── Security Group for EC2 instances ─────────────────────
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow HTTP from ALB only; all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  # Optional: SSH for debugging — restrict to your IP in production
  ingress {
    description = "SSH (restrict this in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ec2-sg" }
}

# ── Launch Template ───────────────────────────────────────
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # User data: installs & starts a simple web server
  # Each instance announces its own hostname so you can see
  # which instance handles each request during failover testing.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf install -y httpd
    systemctl enable --now httpd
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    cat > /var/www/html/index.html <<HTML
    <html>
      <body style="font-family:monospace;padding:40px;background:#f0f4f8">
        <h2>Hello from ALB + ASG Demo</h2>
        <p><b>Instance ID:</b> $INSTANCE_ID</p>
        <p><b>AZ:</b>         $AZ</p>
        <p>If you stop this instance, the ALB will route to another one!</p>
      </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Auto Scaling Group ────────────────────────────────────
resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"          # use ALB health checks, not EC2 default
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Distribute evenly across AZs
 # availability_zone_rebalancing = "enabled"

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
