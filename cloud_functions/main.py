import datetime
import json
import os
from flask import make_response
from google.auth.transport import requests
from google.cloud import datastore
import google.oauth2.id_token
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
PROJECT_ID = os.getenv('GCP_PROJECT')
firebase_request_adapter = requests.Request()

def _get_log_data(request):
    return {
        "body" : request.get_data(),
        "url" : request.url,
        "headers" : request.headers,
        "query": request.query_string,
        "environment": request.environ,
        "method" : request.method
    }


def Log(request):
    logData = _get_log_data(request)
    print (logData)
    response = make_response("Ack")
    response.headers['Access-Control-Allow-Origin'] = '*'
    return response


def StatusZ(request):
    logData = _get_log_data(request)
    print (logData)
    response = make_response("OK")
    response.headers['Access-Control-Allow-Origin'] = '*'
    return response

def Publish(request):
    # Verify Firebase auth.
    id_token = None
    error_message = None
    claims = None
    email = None

    request_data = request.get_data()
    json_map = json.loads(request_data)
    id_token = json_map["fbUserIdToken"]
    topic_name = json_map["topic"]
    topic_path = publisher.topic_path(PROJECT_ID, topic_name)

    payload = json.dumps({"payload": json_map["payload"]})
    payload_bytes = payload.encode('utf-8')

    try:
        claims = google.oauth2.id_token.verify_firebase_token(
            id_token, firebase_request_adapter)
        email = claims["email"]
        print (claims)
    except ValueError as e:
        print(e)
        response = make_response(str(f"{e}"), 500)
        response.headers['Access-Control-Allow-Origin'] = '*'
        return response

    print (f"{email} publishing topic: {topic_path} payload: {payload}")

    try:
        publish_future = publisher.publish(topic_path, data=payload_bytes)
        publish_future.result()  # Verify the publish succeeded
    except Exception as e:
        print(e)
        response = make_response(str(f"{e}"), 500)
        response.headers['Access-Control-Allow-Origin'] = '*'
        return response

    response = make_response(str(f"Message published"))
    response.headers['Access-Control-Allow-Origin'] = '*'
    return response
