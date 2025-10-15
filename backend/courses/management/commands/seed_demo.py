from django.core.management.base import BaseCommand
from courses.models import Course

class Command(BaseCommand):
    help = "Erzeugt Demo-Daten"

    def handle(self, *args, **options):
        titles = ["Django Basics", "GraphQL Fundamentals", "Docker for Devs"]
        created = 0
        for t in titles:
            obj, was_created = Course.objects.get_or_create(title=t)
            created += 1 if was_created else 0
        self.stdout.write(self.style.SUCCESS(f"Demo-Daten erzeugt. Neu erstellt: {created}"))
