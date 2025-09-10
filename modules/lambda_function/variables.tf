variable "function_name" {
description = "The name of the Lambda function."
type = string
}
variable "handler" {
description = "The function entrypoint in your code."
type = string
}
variable "runtime" {
description = "The runtime environment for the Lambda function."
type = string
}
variable "iam_role_arn" {
description = "The ARN of the IAM role for the Lambda function."
type = string
}
variable "filename" {
description = "The local path to the Lambda function's deployment package (zip file)."
type = string
}
variable "source_code_hash" {
description = "The base64-encoded SHA256 hash of the deployment package."
type = string
}
variable "environment_variables" {
description = "A map of environment variables for the Lambda function."
type = map(string)
default = {}
}
variable "tags" {
description = "A map of tags to assign to the function."
type = map(string)
default = {}
}