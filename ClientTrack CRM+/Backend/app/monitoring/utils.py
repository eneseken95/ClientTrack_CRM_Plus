import re


def normalize_path(path: str) -> str:
    path = re.sub(r"/\d+", "/{id}", path)
    return path
