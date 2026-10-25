output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS MySQL database"
  value       = aws_db_instance.mysql.endpoint
}