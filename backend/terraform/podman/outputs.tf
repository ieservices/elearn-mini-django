# ieServices E-Learning Platform - Backend Podman Kubernetes Outputs

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.elearn.metadata[0].name
}

output "backend_service_name" {
  description = "Backend service name"
  value       = kubernetes_service.backend.metadata[0].name
}

output "backend_service_port" {
  description = "Backend service port"
  value       = kubernetes_service.backend.spec[0].port[0].node_port
}

output "backend_url" {
  description = "Backend URL"
  value       = "http://localhost:${kubernetes_service.backend.spec[0].port[0].node_port}"
}

output "postgres_service_name" {
  description = "PostgreSQL service name"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "configmap_name" {
  description = "ConfigMap name"
  value       = kubernetes_config_map.backend_config.metadata[0].name
}

output "secret_name" {
  description = "Secret name"
  value       = kubernetes_secret.backend_secret.metadata[0].name
}
