from elasticsearch import Elasticsearch
from app.core.config import settings

es = Elasticsearch(settings.ELASTICSEARCH_URL)
