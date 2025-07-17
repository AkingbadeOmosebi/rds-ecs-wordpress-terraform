# -------- DB Subnet Group --------
# RDS needs to know where it can create its network interfaces.
resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# -------- RDS MySQL Instance --------
resource "aws_db_instance" "wordpress" {
  allocated_storage    = 20              # 20 GB storage for DB
  storage_type         = "gp2"           # General Purpose SSD
  engine               = "mysql"         # DB engine
  engine_version       = "8.0"           # MySQL version
  instance_class       = "db.t3.micro"   # Smallest cheap instance for demo
  db_name              = var.db_name     # DB name from variables.tf
  username             = var.db_username # Master user
  password             = var.db_password # Master password
  db_subnet_group_name = aws_db_subnet_group.main.name

  # Attach RDS SG to control who can connect (only ECS)
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Don't keep final snapshot when destroying
  skip_final_snapshot = true

  # tag for clarity or just incase moments of confusion
  tags = {
    Name = "${var.project_name}-rds"
  }
}
