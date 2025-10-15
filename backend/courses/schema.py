import graphene
from graphene_django import DjangoObjectType
from .models import Course

class CourseType(DjangoObjectType):
    class Meta:
        model = Course
        fields = ("id", "title", "description", "is_active", "created_at")

class Query(graphene.ObjectType):
    courses = graphene.List(CourseType)
    course = graphene.Field(CourseType, id=graphene.ID(required=True))

    def resolve_courses(root, info):
        return Course.objects.order_by("-created_at").all()

    def resolve_course(root, info, id):
        return Course.objects.filter(pk=id).first()

schema = graphene.Schema(query=Query)
