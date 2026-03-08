# README for Tests

## Running Tests

### Prerequisites

Install development dependencies:
```bash
cd "/Users/Enes/Documents/GitHub/ClientTrack_CRM_Plus/ClientTrack CRM+/Backend"
pip install -r requirements-dev.txt
```

### Run All Tests

```bash
pytest tests/ -v
```

### Run Specific Test Categories

```bash
# Repository tests only
pytest tests/test_repositories/ -v

# Service tests only  
pytest tests/test_services/ -v

# API integration tests only
pytest tests/test_api/ -v
```

### Run Tests with Coverage

```bash
pytest tests/ --cov=app --cov-report=html --cov-report=term
```

This will generate a coverage report in `htmlcov/index.html`.

### Run Tests by Marker

```bash
# Run only unit tests (fast)
pytest -m unit

# Run only integration tests
pytest -m integration
```

## Test Structure

```
tests/
├── conftest.py                     # Global fixtures (DB, mocks, test client)
├── test_repositories/              # Repository layer tests
│   ├── conftest.py
│   ├── test_user_repo.py
│   └── test_client_repo.py
├── test_services/                  # Service layer tests
│   ├── conftest.py
│   ├── test_auth_service.py
│   └── test_client_service.py
└── test_api/                       # API integration tests
    ├── conftest.py
    ├── test_auth_endpoints.py
    └── test_client_endpoints.py
```

## Notes

- Tests use in-memory SQLite database (no external DB required)
- External services (Redis, Elasticsearch, Supabase, Sendgrid) are mocked
- All tests are isolated and can run in any order
- Clean architecture principles are maintained: tests mirror the app structure
