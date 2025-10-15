# ieServices E-Learning Platform - Backend Dockerfile

FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy backend code
COPY . /app/

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -e .

# Collect static files
RUN python manage.py collectstatic --noinput || true

# Create a non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/api/courses/ || exit 1

# Run migrations and start server
CMD python manage.py migrate --noinput && \
    python manage.py collectstatic --noinput && \
    gunicorn elearn.wsgi:application --bind 0.0.0.0:8000 --workers 2 --timeout 120
