import uuid

def short_id():
    return str(uuid.uuid4()).split("-")[0]
