from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from courses.views import CourseViewSet
from django.views.decorators.csrf import csrf_exempt
from graphene_django.views import GraphQLView

router = DefaultRouter()
router.register(r"courses", CourseViewSet, basename="course")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include(router.urls)),
    path("graphql", csrf_exempt(GraphQLView.as_view(graphiql=True))),
]
