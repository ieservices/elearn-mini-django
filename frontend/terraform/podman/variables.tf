# ieServices E-Learning Platform - Frontend Podman Kubernetes Variables

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
  description = "Kubernetes namespace (should match backend namespace)"
  type        = string
  default     = "ieservices-elearn"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "ieservices-elearn"
}

# Frontend Configuration
variable "frontend_image" {
  description = "Docker image for frontend"
  type        = string
  default     = "localhost/ieservices-elearn-frontend:latest"
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 1
}

variable "frontend_node_port" {
  description = "NodePort for frontend service"
  type        = number
  default     = 30300
}

variable "frontend_cpu_request" {
  description = "CPU request for frontend"
  type        = string
  default     = "50m"
}

variable "frontend_memory_request" {
  description = "Memory request for frontend"
  type        = string
  default     = "64Mi"
}

variable "frontend_cpu_limit" {
  description = "CPU limit for frontend"
  type        = string
  default     = "200m"
}

variable "frontend_memory_limit" {
  description = "Memory limit for frontend"
  type        = string
  default     = "128Mi"
}

# Backend API Configuration
variable "backend_api_url" {
  description = "Backend API URL"
  type        = string
  default     = "http://localhost:30800"
}

# Autoscaling Configuration
variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = false
}

variable "autoscaling_min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 5
}
