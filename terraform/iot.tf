# IoT Coreのエンドポイントを取得
data "aws_iot_endpoint" "current" {
  endpoint_type = "iot:Data-ATS"
}

# IoT Core Thing Type
resource "aws_iot_thing_type" "gateway" {
  name = "${var.environment}-gateway"
}

# IoT Core Policy
resource "aws_iot_policy" "gateway_policy" {
  name = "${var.environment}-gateway-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive",
          "iot:GetThingShadow",
          "iot:UpdateThingShadow"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# ECSタスクロールにIoT Core権限を追加
resource "aws_iam_role_policy" "gateway_ecs_task_iot_policy" {
  name = "${var.environment}-gateway-ecs-task-iot-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive",
          "iot:GetThingShadow",
          "iot:UpdateThingShadow"
        ]
        Resource = ["*"]
      }
    ]
  })
}
