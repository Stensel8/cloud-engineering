resource "aws_cloudformation_stack" "elk" {
  name              = "elk-stack"
  template_body     = file("${path.root}/templates/elk_stack.yml")
  notification_arns = var.sns_arn != "" ? [var.sns_arn] : []

  tags = {
    Project      = "CloudShirt"
    Environment  = "prod"
  }
}

output "elk_stack_id" {
  value = aws_cloudformation_stack.elk.id
}
