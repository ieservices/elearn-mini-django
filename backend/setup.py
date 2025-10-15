from setuptools import setup, find_packages

setup(
    name="elearn-mini",
    version="0.1.0",
    description="E-learning Django application with GraphQL API",
    author="ieServices",
    author_email="publisher@ieservices.de",
    packages=find_packages(),
    python_requires=">=3.12",
    install_requires=[
        "Django>=4.2,<5.0",
        "djangorestframework>=3.14",
        "graphene-django>=3.0.0",
        "django-filter>=24.3",
        "django-cors-headers>=4.3.0",
        "requests>=2.32.0",
        "urllib3>=2.2.0",
    ],
    extras_require={
        "dev": [
            "pytest>=8.2.0",
            "pytest-django>=4.9.0",
            "responses>=0.25.0",
            "black>=24.8.0",
            "ruff>=0.6.8",
            "mypy>=1.11.0",
            "types-requests>=2.32.0.20240914",
        ],
    },
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.12",
        "Framework :: Django",
        "Framework :: Django :: 4.2",
    ],
)