# ieServices E-Learning Platform - Frontend Podman Kubernetes Outputs

output "namespace" {
  description = "Kubernetes namespace"
  value       = data.kubernetes_namespace.elearn.metadata[0].name
}

output "frontend_service_name" {
  description = "Frontend service name"
  value       = kubernetes_service.frontend.metadata[0].name
}

output "frontend_service_port" {
  description = "Frontend service NodePort"
  value       = kubernetes_service.frontend.spec[0].port[0].node_port
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://localhost:${kubernetes_service.frontend.spec[0].port[0].node_port}"
}

output "deployment_name" {
  description = "Frontend deployment name"
  value       = kubernetes_deployment.frontend.metadata[0].name
}

output "configmap_nginx_name" {
  description = "Nginx ConfigMap name"
  value       = kubernetes_config_map.nginx_config.metadata[0].name
}

output "configmap_env_name" {
  description = "Environment ConfigMap name"
  value       = kubernetes_config_map.frontend_env.metadata[0].name
}
