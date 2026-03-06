CLIENT_INDEX = "clients"
CLIENT_MAPPING = {
    "settings": {
        "analysis": {
            "analyzer": {
                "autocomplete": {
                    "tokenizer": "autocomplete_tokenizer",
                    "filter": ["lowercase"],
                },
                "autocomplete_search": {"tokenizer": "lowercase"},
            },
            "tokenizer": {
                "autocomplete_tokenizer": {
                    "type": "edge_ngram",
                    "min_gram": 1,
                    "max_gram": 20,
                    "token_chars": ["letter", "digit"],
                }
            },
        }
    },
    "mappings": {
        "properties": {
            "id": {"type": "integer"},
            "name": {
                "type": "text",
                "analyzer": "autocomplete",
                "search_analyzer": "autocomplete_search",
            },
            "surname": {
                "type": "text",
                "analyzer": "autocomplete",
                "search_analyzer": "autocomplete_search",
            },
            "company": {
                "type": "text",
                "analyzer": "autocomplete",
                "search_analyzer": "autocomplete_search",
            },
            "notes": {
                "type": "text",
                "analyzer": "autocomplete",
                "search_analyzer": "autocomplete_search",
            },
            "email": {
                "type": "text",
                "analyzer": "autocomplete",
                "search_analyzer": "autocomplete_search",
                "fields": {"keyword": {"type": "keyword"}},
            },
            "phone": {"type": "keyword"},
            "owner_id": {"type": "integer"},
            "company_logo": {"type": "keyword"},
        }
    },
}
