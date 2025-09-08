# modules/lambda_function/variables.tf
variable "package_path" {
  description = "The path to the pre-built Lambda deployment package (ZIP file)."
  type        = string
}

variable "project_name" {
  type = string
}

variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

#variable "source_path" {
 # description = "The path to the directory containing the Lambda source code."
  #type        = string
#}

variable "handler" {
  description = "The handler for the Lambda function (e.g., 'app.handler')."
  type        = string
}

variable "runtime" {
  description = "The runtime for the Lambda function (e.g., 'python3.9')."
  type        = string
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  type        = string
}

variable "memory_size" {
  description = "The amount of memory in MB for the function."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "The timeout in seconds for the function."
  type        = number
  default     = 30
}

variable "environment_variables" {
  description = "A map of environment variables for the function."
  type        = map(string)
  default     = {}
}

#variable "s3_bucket_arn" {
#  description = "The ARN of the S3 bucket that will trigger this function. Set to null if not used."
#  type        = string
#  default     = null
#}

#variable "api_gateway_execution_arn" {
#  description = "The execution ARN of the API Gateway that will trigger this function. Set to null if not used."
#  type        = string
#  default     = null
#}


#variable "output_path" {
 # description = "The output path for the ZIP file, relative to the root module."
 # type        = string
#}