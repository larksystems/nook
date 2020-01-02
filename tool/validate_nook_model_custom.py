# Custom type validation functions

import validate_nook_model as model

conversationTagIds = []
messageTagIds = []

def validate_Conversation(fieldPath, docId, data):
    validate_ConversationId(f"{fieldPath}/doc-id", docId)
    model.validate_Conversation(fieldPath, data)

def validate_ConversationTag(fieldPath, docId, data):
    validate_TagId(f"{fieldPath}/doc-id", docId)
    conversationTagIds.append(docId)
    model.validate_Tag(fieldPath, data)

def validate_MessageTag(fieldPath, docId, data):
    validate_TagId(f"{fieldPath}/doc-id", docId)
    messageTagIds.append(docId)
    model.validate_Tag(fieldPath, data)

def validate_ConversationId(fieldPath, value):
    if value is None:
        raise model.ValidationError(f"{fieldPath} is undefined")
    if value.startswith("nook-phone-uuid-"):
        return
    raise model.ValidationError(f"{fieldPath} invalid: {value}")

def validate_ConversationTagId(fieldPath, value):
    validate_TagId(fieldPath, value)
    if not value in conversationTagIds:
        raise model.ValidationError(f"{fieldPath} {value} is not one of {conversationTagIds}")

def validate_MessageTagId(fieldPath, value):
    validate_TagId(fieldPath, value)
    if not value in messageTagIds:
        raise model.ValidationError(f"{fieldPath} {value} is not one of {messageTagIds}")

def validate_TagId(fieldPath, value):
    if value is None:
        raise model.ValidationError(f"{fieldPath} is undefined")
    if value.startswith("tag-"):
        return
    raise model.ValidationError(f"{fieldPath} invalid: {value}")
