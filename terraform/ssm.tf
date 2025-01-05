resource "aws_ssm_parameter" "iot_certificate" {
  name  = "/${var.project}/${var.environment}/iot/certificate"
  type  = "SecureString"
  value = file("certificate.pem.crt")
}

resource "aws_ssm_parameter" "iot_private_key" {
  name  = "/${var.project}/${var.environment}/iot/private-key"
  type  = "SecureString"
  value = file("private.pem.key")
}
