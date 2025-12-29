# -------- ECS Cluster --------
# Think of this as the 'pool' where your containers run
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# -------- Task Execution Role --------
# Fargate needs permissions to pull images, log stuff, etc.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for ECS execution — gives permission to pull images & push logs
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------- ECS Task Definition --------
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  
  # Add task role for additional permissions
  task_role_arn = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:6.5-apache"  # Use specific version instead of latest
      essential = true
      
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = aws_db_instance.wordpress.address
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.db_username
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.db_name
        },
        {
          name  = "WORDPRESS_CONFIG_EXTRA"
          value = "define('WP_HOME','http://${aws_lb.main.dns_name}'); define('WP_SITEURL','http://${aws_lb.main.dns_name}');"
        }
      ]
      
      # Add health check
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      
      # Add logging
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  # Add volume for WordPress uploads (optional - consider EFS for production)
  # volume {
  #   name = "wordpress-uploads"
  # }
}

# -------- CloudWatch Logs Group --------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-logs"
  }
}

# -------- ECS Task Role --------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


# -------- ECS Service --------
resource "aws_ecs_service" "wordpress" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  launch_type     = "FARGATE"
  desired_count   = 2
  
  # Enable deployment circuit breaker
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Deployment configuration
  deployment_controller {
    type = "ECS"
  }
  
  network_configuration {
    subnets = [
      aws_subnet.private_1.id,  # Changed from public to private
      aws_subnet.private_2.id   # Changed from public to private
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false  # Changed from true to false (no public IP needed with NAT)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  # Ensure RDS is ready before ECS starts
  depends_on = [
    aws_lb_listener.http,
    aws_db_instance.wordpress
  ]
  
  # Service discovery (optional)
  service_registries {
    registry_arn = aws_service_discovery_service.wordpress.arn
  }
}

# -------- Service Discovery --------
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Service discovery namespace for WordPress"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "wordpress" {
  name = "wordpress"
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
    
    routing_policy = "MULTIVALUE"
  }
  
  health_check_custom_config {
    failure_threshold = 1
  }
}