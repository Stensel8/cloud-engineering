variable "db_password" {
  type      = string
  sensitive = true
}

variable "sns_arn" {
  description = "SNS topic ARN for CloudFormation stack event notifications"
  type        = string
  default     = ""
}
