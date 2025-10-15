# ieServices E-Learning Platform - Backend Podman Kubernetes Deployment
# This Terraform configuration deploys the Django backend to a local Podman Kubernetes cluster

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

# Namespace for the application
resource "kubernetes_namespace" "elearn" {
  metadata {
    name = var.namespace

    labels = {
      app     = "ieservices-elearn"
      env     = var.environment
      component = "backend"
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "backend_config" {
  metadata {
    name      = "${var.app_name}-backend-config"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "backend"
    }
  }

  data = {
    DEBUG                = var.debug_mode
    ALLOWED_HOSTS        = var.allowed_hosts
    DATABASE_HOST        = "${var.app_name}-postgres"
    DATABASE_PORT        = "5432"
    DATABASE_NAME        = var.db_name
    CORS_ALLOWED_ORIGINS = var.cors_allowed_origins
  }
}

# Secret for sensitive data
resource "kubernetes_secret" "backend_secret" {
  metadata {
    name      = "${var.app_name}-backend-secret"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "backend"
    }
  }

  type = "Opaque"

  data = {
    DJANGO_SECRET_KEY = base64encode(var.django_secret_key)
    DATABASE_USER     = base64encode(var.db_username)
    DATABASE_PASSWORD = base64encode(var.db_password)
  }
}

# PostgreSQL PersistentVolumeClaim
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "${var.app_name}-postgres-pvc"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "database"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.postgres_storage_size
      }
    }
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "${var.app_name}-postgres"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "database"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = var.app_name
        component = "database"
      }
    }

    template {
      metadata {
        labels = {
          app       = var.app_name
          component = "database"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "docker.io/library/postgres:15-alpine"

          port {
            container_port = 5432
            name          = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = var.db_name
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DATABASE_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DATABASE_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_username]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.db_username]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# PostgreSQL Service
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "${var.app_name}-postgres"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "database"
    }
  }

  spec {
    selector = {
      app       = var.app_name
      component = "database"
    }

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
      name        = "postgres"
    }

    type = "ClusterIP"
  }
}

# Backend Deployment
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "${var.app_name}-backend"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "backend"
    }
  }

  spec {
    replicas = var.backend_replicas

    selector {
      match_labels = {
        app       = var.app_name
        component = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app       = var.app_name
          component = "backend"
        }
      }

      spec {
        init_container {
          name  = "wait-for-postgres"
          image = "docker.io/library/busybox:latest"

          command = [
            "sh",
            "-c",
            "until nc -z ${var.app_name}-postgres 5432; do echo waiting for postgres; sleep 2; done;"
          ]
        }

        container {
          name  = "backend"
          image = var.backend_image

          port {
            container_port = 8000
            name          = "http"
          }

          env {
            name = "DJANGO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DJANGO_SECRET_KEY"
              }
            }
          }

          env {
            name = "DATABASE_URL"
            value = "postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"
          }

          env {
            name = "DATABASE_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DATABASE_USER"
              }
            }
          }

          env {
            name = "DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DATABASE_PASSWORD"
              }
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend_config.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.backend_cpu_request
              memory = var.backend_memory_request
            }
            limits = {
              cpu    = var.backend_cpu_limit
              memory = var.backend_memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/api/courses/"
              port = 8000
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/courses/"
              port = 8000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_deployment.postgres
  ]
}

# Backend Service
resource "kubernetes_service" "backend" {
  metadata {
    name      = "${var.app_name}-backend"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "backend"
    }
  }

  spec {
    selector = {
      app       = var.app_name
      component = "backend"
    }

    port {
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
      name        = "http"
      node_port   = var.backend_node_port
    }

    type = "NodePort"
  }
}

# Job for running migrations
resource "kubernetes_job" "migrate" {
  metadata {
    name      = "${var.app_name}-migrate-${formatdate("YYYYMMDDhhmmss", timestamp())}"
    namespace = kubernetes_namespace.elearn.metadata[0].name

    labels = {
      app       = var.app_name
      component = "migration"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app       = var.app_name
          component = "migration"
        }
      }

      spec {
        restart_policy = "OnFailure"

        init_container {
          name  = "wait-for-postgres"
          image = "docker.io/library/busybox:latest"

          command = [
            "sh",
            "-c",
            "until nc -z ${var.app_name}-postgres 5432; do echo waiting for postgres; sleep 2; done;"
          ]
        }

        container {
          name    = "migrate"
          image   = var.backend_image
          command = ["python", "manage.py", "migrate", "--noinput"]

          env {
            name = "DJANGO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DJANGO_SECRET_KEY"
              }
            }
          }

          env {
            name = "DATABASE_URL"
            value = "postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"
          }

          env {
            name = "DATABASE_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DATABASE_USER"
              }
            }
          }

          env {
            name = "DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backend_secret.metadata[0].name
                key  = "DATABASE_PASSWORD"
              }
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend_config.metadata[0].name
            }
          }
        }
      }
    }

    backoff_limit = 3
  }

  wait_for_completion = true

  depends_on = [
    kubernetes_deployment.postgres
  ]

  lifecycle {
    ignore_changes = [
      metadata[0].name
    ]
  }
}
