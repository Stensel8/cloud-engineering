resource "aws_cloudformation_stack" "rds" {
  name              = "rds-stack"
  template_body     = file("${path.root}/templates/rds_stack.yml")
  notification_arns = var.sns_arn != "" ? [var.sns_arn] : []

  parameters = {
    DBAllocatedStorage = "30"
  }

  tags = {
    Project     = "CloudShirt"
    Environment = "prod"
  }
}

output "rds_stack_id" {
  value = aws_cloudformation_stack.rds.id
}
