variable "environment" {
  description = "El entorno a desplegar (ej. dev o staging)"
  type        = string
}

variable "app_message" {
  description = "Mensaje a mostrar en la web"
  type        = string
}

variable "image_tag" {
  description = "El tag de la imagen Docker (generalmente el Commit SHA)"
  type        = string
  default     = "latest"
}

variable "replica_count" {
  description = "Número de réplicas para el backend"
  type        = number
}