# ieServices E-Learning Platform - Frontend Podman Kubernetes Deployment
# This Terraform configuration deploys the React frontend to a local Podman Kubernetes cluster

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubernetes_context
}

# Use existing namespace (created by backend deployment)
data "kubernetes_namespace" "elearn" {
  metadata {
    name = var.namespace
  }
}

# ConfigMap for Nginx configuration
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "${var.app_name}-frontend-nginx-config"
    namespace = data.kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "frontend"
    }
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen 80;
          server_name localhost;
          root /usr/share/nginx/html;
          index index.html;

          # Gzip compression
          gzip on;
          gzip_vary on;
          gzip_min_length 1024;
          gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;

          # Security headers
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-XSS-Protection "1; mode=block" always;

          # Cache static assets
          location /static/ {
              expires 1y;
              add_header Cache-Control "public, immutable";
          }

          # SPA routing - serve index.html for all routes
          location / {
              try_files $uri $uri/ /index.html;
              add_header Cache-Control "no-cache";
          }

          # Health check endpoint
          location /health {
              access_log off;
              return 200 "healthy\n";
              add_header Content-Type text/plain;
          }
      }
    EOT
  }
}

# ConfigMap for environment configuration
resource "kubernetes_config_map" "frontend_env" {
  metadata {
    name      = "${var.app_name}-frontend-env"
    namespace = data.kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "frontend"
    }
  }

  data = {
    REACT_APP_API_URL = var.backend_api_url
  }
}

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "${var.app_name}-frontend"
    namespace = data.kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "frontend"
    }
  }

  spec {
    replicas = var.frontend_replicas

    selector {
      match_labels = {
        app       = var.app_name
        component = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app       = var.app_name
          component = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = var.frontend_image

          port {
            container_port = 80
            name          = "http"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = var.frontend_cpu_request
              memory = var.frontend_memory_request
            }
            limits = {
              cpu    = var.frontend_cpu_limit
              memory = var.frontend_memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Frontend Service
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "${var.app_name}-frontend"
    namespace = data.kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "frontend"
    }
  }

  spec {
    selector = {
      app       = var.app_name
      component = "frontend"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
      node_port   = var.frontend_node_port
    }

    type = "NodePort"
  }
}

# Horizontal Pod Autoscaler (optional)
resource "kubernetes_horizontal_pod_autoscaler_v2" "frontend" {
  count = var.enable_autoscaling ? 1 : 0

  metadata {
    name      = "${var.app_name}-frontend-hpa"
    namespace = data.kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "frontend"
    }
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.frontend.metadata[0].name
    }

    min_replicas = var.autoscaling_min_replicas
    max_replicas = var.autoscaling_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
