output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "rest_target_group_arn" {
  description = "REST API target group ARN"
  value       = aws_lb_target_group.rest.arn
}

output "events_target_group_arn" {
  description = "Events WebSocket target group ARN"
  value       = aws_lb_target_group.events.arn
}

output "target_group_arns" {
  description = "List of all target group ARNs"
  value       = [aws_lb_target_group.rest.arn, aws_lb_target_group.events.arn]
}
