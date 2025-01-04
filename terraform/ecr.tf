resource "aws_ecr_repository" "gateway_app" {
  name = "gateway-app"
}

# ライフサイクルポリシーの追加（必要な場合）
resource "aws_ecr_lifecycle_policy" "gateway_app" {
  repository = aws_ecr_repository.gateway_app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = {
        type = "expire"
      }
    }]
  })
}
