variable "aws_region" {
  description = "Región de despliegue en AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo de recursos del proyecto"
  type        = string
  default     = "devops-final"
}

variable "lab_role_name" {
  description = "Rol IAM existente de AWS Academy (Learner Lab no permite crear roles)"
  type        = string
  default     = "LabRole"
}
