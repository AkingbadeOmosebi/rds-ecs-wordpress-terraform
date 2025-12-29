# -------- Outputs --------

# ALB DNS name, this is the public URL of my WordPress site, basically the like the URL to my WorrdPress site.
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# RDS Endpoint, this will show where my DB is running
output "rds_endpoint" {
  description = "The endpoint of the RDS database"
  value       = aws_db_instance.wordpress.address
  sensitive   = true # so your DB endpoint stays kinda protected in output
}

# ECS Cluster name, I think this is also nice to have
output "ecs_cluster_name" {
  description = "The name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}
