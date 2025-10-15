import pytest
from django.test import Client
from courses.models import Course

@pytest.mark.django_db
def test_graphql_courses_query():
    Course.objects.create(title="GraphQL Fundamentals")
    client = Client()
    query = {"query": "{ courses { id title isActive } }"}
    resp = client.post("/graphql", data=query, content_type="application/json")
    assert resp.status_code == 200
    data = resp.json()
    assert "data" in data
    titles = [c["title"] for c in data["data"]["courses"]]
    assert "GraphQL Fundamentals" in titles
