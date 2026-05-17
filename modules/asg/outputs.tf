##############################################################
# modules/asg/outputs.tf
##############################################################
output "asg_name"    { value = aws_autoscaling_group.app.name }
output "lt_id"       { value = aws_launch_template.app.id }
output "ec2_sg_id"   { value = aws_security_group.ec2.id }
