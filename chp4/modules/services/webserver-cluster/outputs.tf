output "asg_name" {
  value       = aws_autoscaling_group.asg_web.name
  description = "The name of the auto scaling group"
}

output "alb_dns_name" {
  value       = aws_lb.sg_alb.dns_name
  description = "The domain name of the load balancer"
}