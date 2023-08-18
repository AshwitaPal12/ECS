variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
  default = "ecs-cluster"
}

variable "service_name" {
  type        = string
  description = "ECS service name"
  default = "ecs-service"
}

variable "task_family" {
  type        = string
  description = "ECS task family"
  default = "my-task-family"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
  default     = null
}

variable "network_mode" {
  type        = string
  description = "ECS network mode"
  default     = "bridge"
}

variable "launch_type" {
  description = "ECS launch type"
  type = object({
    type   = string
    cpu    = number
    memory = number
  })
  default = {
    type   = "EC2"
    cpu    = 256
    memory = 512
  }
}