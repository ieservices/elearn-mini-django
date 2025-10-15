from django.core.management.base import BaseCommand
from courses.models import Course

class Command(BaseCommand):
    help = "Erzeugt Demo-Daten"

    def handle(self, *args, **options):
        courses_data = [
            {
                "title": "Django Basics",
                "description": "Master the fundamentals of Django, the powerful Python web framework. Learn how to build robust, scalable web applications with best practices in MVC architecture, ORM, templating, and authentication. Perfect for developers ready to accelerate their backend development skills."
            },
            {
                "title": "GraphQL Fundamentals",
                "description": "Dive into the world of modern API development with GraphQL. Discover how to create flexible, efficient APIs that give clients exactly what they need. Learn schema design, queries, mutations, and real-time subscriptions. Transform the way you think about data fetching and API architecture."
            },
            {
                "title": "Docker for Devs",
                "description": "Unlock the power of containerization and revolutionize your development workflow. Learn Docker from the ground up: create containers, manage images, orchestrate multi-container applications, and deploy with confidence. Essential skills for modern DevOps and cloud-native development."
            }
        ]
        created = 0
        for course_data in courses_data:
            obj, was_created = Course.objects.get_or_create(
                title=course_data["title"],
                defaults={"description": course_data["description"]}
            )
            if not was_created and not obj.description:
                obj.description = course_data["description"]
                obj.save()
            created += 1 if was_created else 0
        self.stdout.write(self.style.SUCCESS(f"Demo-Daten erzeugt. Neu erstellt: {created}"))
