FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app

COPY requirements.txt /app/

RUN pip install --default-timeout=200 -r requirements.txt

COPY . /app/

CMD ["bash","-lc","alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
