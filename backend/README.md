# elearn — Mini Django Projekt (DRF + GraphQL + SAP-SF Stub)

**Ziel:** Sofort startbares Mini-Projekt, passend zu einem eLearning-Use-Case.

## Features
- Django 4 + SQLite
- **Django REST Framework** (`/api/courses/`) – list/create
- **GraphQL** über Graphene (`/graphql`) inkl. GraphiQL UI
- **SAP SuccessFactors OData Client (Stub)** mit Retry/Timeout & Tests
- Dockerfile + docker-compose
- Bitbucket Pipeline (Lint + Tests)
- `black`, `ruff`, `mypy`, `pytest` Setup

## Schnellstart (ohne Docker)
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
export DJANGO_SECRET_KEY="dev-secret"  # Windows: set DJANGO_SECRET_KEY=dev-secret
python manage.py migrate
python manage.py seed_demo          # Demo-Daten
python manage.py runserver 0.0.0.0:8000
```
- API: http://127.0.0.1:8000/api/courses/
- GraphQL (mit UI): http://127.0.0.1:8000/graphql

## Schnellstart (Docker)
```bash
docker build -t elearn .
docker run --rm -p 8000:8000 elearn
# oder
docker compose up --build
```

## Tests
```bash
pytest -q
```

## Ordnerstruktur
```
elearn/
  elearn/            # Projekteinstellungen
  courses/           # App mit API, GraphQL, SAP-SF Stub, Tests
  requirements.txt
  Dockerfile
  docker-compose.yml
  bitbucket-pipelines.yml
  pyproject.toml
  pytest.ini
  .env.example
```
