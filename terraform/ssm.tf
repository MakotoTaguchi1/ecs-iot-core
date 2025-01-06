resource "aws_ssm_parameter" "iot_certificate" {
  name  = "/${var.project}/${var.environment}/iot/certificate"
  type  = "SecureString"
  value = aws_iot_certificate.gateway.certificate_pem
}

resource "aws_ssm_parameter" "iot_private_key" {
  name  = "/${var.project}/${var.environment}/iot/private-key"
  type  = "SecureString"
  value = aws_iot_certificate.gateway.private_key
}
