import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from courses.models import Course

@pytest.mark.django_db
def test_list_courses():
    Course.objects.create(title="Django Basics")
    client = APIClient()
    resp = client.get("/api/courses/")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
    assert resp.json()[0]["title"] == "Django Basics"

@pytest.mark.django_db
def test_create_course():
    client = APIClient()
    resp = client.post("/api/courses/", {"title": "New Course", "is_active": True}, format="json")
    assert resp.status_code == 201
    assert resp.json()["title"] == "New Course"
