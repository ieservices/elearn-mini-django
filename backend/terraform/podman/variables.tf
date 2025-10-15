# ieServices E-Learning Platform - Backend Podman Kubernetes Variables

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "podman"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "ieservices-elearn"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "ieservices-elearn"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "local"
}

# Backend Configuration
variable "backend_image" {
  description = "Docker image for backend"
  type        = string
  default     = "localhost/ieservices-elearn-backend:latest"
}

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 1
}

variable "backend_node_port" {
  description = "NodePort for backend service"
  type        = number
  default     = 30800
}

variable "backend_cpu_request" {
  description = "CPU request for backend"
  type        = string
  default     = "100m"
}

variable "backend_memory_request" {
  description = "Memory request for backend"
  type        = string
  default     = "256Mi"
}

variable "backend_cpu_limit" {
  description = "CPU limit for backend"
  type        = string
  default     = "500m"
}

variable "backend_memory_limit" {
  description = "Memory limit for backend"
  type        = string
  default     = "512Mi"
}

# Database Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "elearn"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "elearn_admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "elearn_password"
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "5Gi"
}

# Application Configuration
variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
  default     = "local-dev-secret-key-change-in-production"
}

variable "debug_mode" {
  description = "Django debug mode"
  type        = string
  default     = "1"
}

variable "allowed_hosts" {
  description = "Django allowed hosts"
  type        = string
  default     = "*"
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = string
  default     = "http://localhost:3000,http://localhost:30300"
}
