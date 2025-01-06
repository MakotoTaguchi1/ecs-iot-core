resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.environment}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project}-${var.environment}-app"
      image = "${aws_ecr_repository.gateway_app.repository_url}:latest"
      environment = [
        {
          name  = "AWS_IOT_ENDPOINT"
          value = data.aws_iot_endpoint.current.endpoint_address
        },
        {
          name  = "IOT_THING_NAME"
          value = aws_iot_thing.gateway.name
        }
      ]
      secrets = [
        {
          name      = "CERTIFICATE"
          valueFrom = aws_ssm_parameter.iot_certificate.arn
        },
        {
          name      = "PRIVATE_KEY"
          valueFrom = aws_ssm_parameter.iot_private_key.arn
        }
      ]
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}-${var.environment}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  #   load_balancer {
  #     target_group_arn = aws_lb_target_group.app.arn
  #     container_name   = "${var.project}-${var.environment}-app"
  #     container_port   = var.container_port
  #   }

  #   depends_on = [aws_lb_listener.app]
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project}-${var.environment}-ecs-tasks"
  description = "Allow all outbound traffic for debugging"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0 # すべてのポート
    to_port     = 0
    protocol    = "-1"          # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"] # すべての送信先
  }
}
