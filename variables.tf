# -------- Variables for our project --------

# Region to deploy in (Frankfurt 🇩🇪 by default)
variable "aws_region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "eu-central-1"
}

# Project prefix for naming resources
variable "project_name" {
  description = "Prefix to use for all resource names"
  type        = string
  default     = "wp-ecs"
}

# Database username for RDS
variable "db_username" {
  description = "Master username for the MySQL DB"
  type        = string
  default     = "admin"
}

# Database password — we’ll override this in tfvars or Spacelift, not here!
variable "db_password" {
  description = "Master password for the MySQL DB"
  type        = string
  sensitive   = true
}

# Name of our database
variable "db_name" {
  description = "Name of the WordPress database"
  type        = string
  default     = "wordpressdb"
}
