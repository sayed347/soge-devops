variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type    = string
  default = null
}

variable "image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  description = "Map of container env var name to a Secrets Manager valueFrom reference (<secret-arn>:<json-key>::)"
  type        = map(string)
  default     = {}
}

variable "target_group_arn" {
  type = string
}

variable "ingress_security_group_id" {
  description = "Security group (typically the service's ALB) allowed to reach this service on container_port"
  type        = string
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 6
}

variable "cpu_target" {
  type    = number
  default = 60
}

variable "log_retention_days" {
  type    = number
  default = 14
}
