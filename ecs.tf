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
# This is the 'recipe' for your WordPress container
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"    # Needed for Fargate
  requires_compatibilities = ["FARGATE"] # We use Fargate, no EC2 to manage
  cpu                      = 512         # 0.5 vCPU
  memory                   = 1024        # 1 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:latest" # Official WordPress image from Docker Hub, you can also put ECR public WordPress image here
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
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
        }
      ]
    }
  ])
}


# -------- ECS Service --------
# Keeps tasks alive & hooks them to ALB
resource "aws_ecs_service" "wordpress" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # 2 containers for high availability, 1 is for just one only, but for production you should have at least 2 or more

  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Needed since we’re in public subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http] # Make sure ALB listener exists first
}
