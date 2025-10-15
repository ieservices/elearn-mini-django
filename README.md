# ieServices E-Learning Platform

A full-stack e-learning application powered by ieServices, built with Django backend and React frontend, using GraphQL for communication.

## Project Structure

```
.
├── backend/          # Django application
│   ├── courses/     # Courses app with models, views, and GraphQL schema
│   ├── elearn/      # Main Django project settings
│   └── setup.py     # Python package configuration
└── frontend/        # React application
    ├── src/
    │   ├── components/     # React components
    │   ├── graphql/        # GraphQL queries
    │   └── apollo-client.js # Apollo Client setup
    └── package.json
```

## Backend Setup

The backend is a Django application with GraphQL API and REST API endpoints.

### Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies using setup.py:
```bash
pip install -e .
# For development dependencies
pip install -e .[dev]
```

3. Run migrations:
```bash
python manage.py migrate
```

4. (Optional) Load demo data:
```bash
python manage.py seed_demo
```

5. Start the development server:
```bash
python manage.py runserver
```

The backend will be available at `http://localhost:8000`

### API Endpoints

- **REST API**: `http://localhost:8000/api/courses/`
- **GraphQL**: `http://localhost:8000/graphql`
- **GraphiQL Interface**: `http://localhost:8000/graphql` (interactive GraphQL explorer)

### GraphQL Schema

```graphql
type Course {
  id: ID!
  title: String!
  description: String!
  isActive: Boolean!
  createdAt: DateTime!
}

type Query {
  courses: [Course]
  course(id: ID!): Course
}
```

## Frontend Setup

The frontend is a React application using Apollo Client for GraphQL communication.

### Installation

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm start
```

The frontend will be available at `http://localhost:3000`

## Running the Full Stack

1. Start the Django backend:
```bash
cd backend
python manage.py runserver
```

2. In a new terminal, start the React frontend:
```bash
cd frontend
npm start
```

3. Open your browser to `http://localhost:3000` to see the application

## Features

### Backend
- Django 4.2+ with REST Framework
- GraphQL API using graphene-django
- CORS support for frontend communication
- SQLite database
- Course model with admin interface
- Test suite with pytest

### Frontend
- React 18 with hooks
- Apollo Client for GraphQL
- Responsive design with ieServices branding
- Loading and error states
- Interactive course listing with expandable descriptions
- Click-to-reveal course details

## Development

### Backend Testing
```bash
cd backend
pytest
```

### Backend Code Quality
```bash
# Format code
black .

# Lint
ruff check .

# Type checking
mypy .
```

## Environment Variables

### Backend
- `DJANGO_SECRET_KEY`: Django secret key (default: "dev-secret")
- `DEBUG`: Debug mode (default: "1")
- `ALLOWED_HOSTS`: Comma-separated allowed hosts (default: "*")

## Technologies Used

### Backend
- Django 4.2+
- Django REST Framework
- graphene-django
- django-cors-headers

### Frontend
- React 18
- Apollo Client
- GraphQL

## Deployment Options

The project includes comprehensive Terraform configurations for two deployment options:

### 1. Local Deployment with Podman Kubernetes

Perfect for local development and testing on your machine.

#### Backend (Podman Kubernetes)

Located in `backend/terraform/podman/`:

- **Infrastructure**: Kubernetes Namespace, PostgreSQL Pod with PVC, Django on ECS-like pods
- **Features**: Init containers, health checks, automatic migrations, ConfigMaps & Secrets
- **Cost**: Free (runs locally)
- **Documentation**: See `backend/terraform/podman/README.md`

Quick start:
```bash
# Build backend image
cd backend
podman build -t localhost/ieservices-elearn-backend:latest -f terraform/aws/Dockerfile .

# Deploy with Terraform
cd terraform/podman
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# Access at http://localhost:30800
```

#### Frontend (Podman Kubernetes)

Located in `frontend/terraform/podman/`:

- **Infrastructure**: React + Nginx in Pods, custom Nginx config for SPA routing
- **Features**: Health checks, resource limits, optional HPA
- **Cost**: Free (runs locally)
- **Documentation**: See `frontend/terraform/podman/README.md`

Quick start:
```bash
# Build frontend image
cd frontend
podman build -t localhost/ieservices-elearn-frontend:latest .

# Deploy with Terraform
cd terraform/podman
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# Access at http://localhost:30300
```

### 2. AWS Cloud Deployment

Production-ready cloud deployment with managed services.

#### Backend (AWS ECS Fargate)

Located in `backend/terraform/aws/`:

- **Infrastructure**: VPC, ECS Fargate, RDS PostgreSQL, Application Load Balancer
- **Features**: Auto-scaling, CloudWatch logging, Multi-AZ deployment
- **Cost**: ~$40-60/month for dev environment
- **Documentation**: See `backend/terraform/aws/README.md`

Quick start:
```bash
cd backend/terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

#### Frontend (AWS S3 + CloudFront)

Located in `frontend/terraform/aws/`:

- **Infrastructure**: S3 static hosting, CloudFront CDN, optional Route53
- **Features**: Global CDN, HTTPS, automatic cache invalidation
- **Cost**: ~$5-15/month for dev environment
- **Documentation**: See `frontend/terraform/aws/README.md`

Quick start:
```bash
cd frontend/terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your backend API URL
terraform init
terraform apply
```

Deploy the frontend:
```bash
cd frontend
chmod +x deploy.sh
./deploy.sh dev
```

### Deployment Comparison

| Feature | Podman Kubernetes | AWS Cloud |
|---------|-------------------|-----------|
| **Cost** | Free | ~$45-75/month |
| **Setup** | Local machine | AWS account required |
| **Database** | PostgreSQL in Pod | RDS PostgreSQL |
| **Scaling** | Manual/HPA | Auto-scaling |
| **Availability** | Single machine | Multi-AZ |
| **Best For** | Development, Testing | Production, Staging |

For detailed deployment instructions, cost estimates, and troubleshooting, refer to the README files in each terraform directory.

## About ieServices

ieServices is a leading provider of innovative technology solutions, specializing in educational platforms and enterprise software services.

## License

This project is for educational purposes.