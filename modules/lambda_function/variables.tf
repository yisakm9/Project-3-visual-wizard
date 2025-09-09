variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code (e.g., 'image_processing.handler')."
  type        = string
}

variable "runtime" {
  description = "The runtime environment for the Lambda function."
  type        = string
  default     = "python3.11"
}

variable "source_path" {
  description = "The local path to the directory containing the Lambda function code."
  type        = string
}

variable "role_arn" {
  description = "The ARN of the IAM role to associate with the Lambda function."
  type        = string
}

variable "environment_variables" {
  description = "A map of environment variables to pass to the function."
  type        = map(string)
  default     = {}
}

variable "memory_size" {
  description = "The amount of memory in MB to allocate to the function."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "The amount of time in seconds the function has to run."
  type        = number
  default     = 30
}

variable "tags" {
  description = "A map of tags to apply to the Lambda function."
  type        = map(string)
  default     = {}
}