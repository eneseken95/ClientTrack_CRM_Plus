from app.core.elasticsearch import es
from app.search.client_index import CLIENT_INDEX, CLIENT_MAPPING
from elasticsearch import exceptions
import time


def ensure_client_index(retries: int = 15, delay: int = 2):
    for attempt in range(retries):
        try:
            es.info()
            try:
                exists = es.indices.exists(index=CLIENT_INDEX)
            except exceptions.BadRequestError:
                exists = False
            if not exists:
                es.indices.create(index=CLIENT_INDEX, **CLIENT_MAPPING)
            return
        except exceptions.ConnectionError:
            time.sleep(delay)
