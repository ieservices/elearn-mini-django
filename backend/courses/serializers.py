from rest_framework import serializers
from .models import Course

class CourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = ["id", "title", "description", "is_active", "created_at"]
        read_only_fields = ["id", "created_at"]
