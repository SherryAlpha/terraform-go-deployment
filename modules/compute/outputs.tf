output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

output "elastic_ip" {
  description = "Elastic IP for direct access"
  value       = aws_eip.app.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = aws_eip.app.allocation_id
}