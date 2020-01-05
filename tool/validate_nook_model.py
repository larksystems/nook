# Each of these functions are used to validate data from a firebase document
# and raise a ValidationError if a discrepancy is found

from datetime import datetime

import validate_nook_model_custom as custom

# ----------------------------------------------------------------------
# Generated type validation functions that might be slightly hand modified

def validate_Conversation_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_Conversation(fieldPath, data[fieldName])

def validate_Conversation(fieldPath, data):
    validate_Map_field(f"{fieldPath}/demographicsInfo", data, validate_String, notEmpty = False)
    validate_List_field(f"{fieldPath}/tags", data, custom.validate_ConversationTagId, notEmpty = False)
    validate_List_field(f"{fieldPath}/messages", data, validate_Message)
    validate_String_field(f"{fieldPath}/notes", data, notEmpty = False)
    validate_bool_field(f"{fieldPath}/unread", data, required = False)

def validate_Message_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_Message(fieldPath, data[fieldName])

def validate_Message(fieldPath, data):
    validate_MessageDirection_field(f"{fieldPath}/direction", data)
    validate_DateTime_field(f"{fieldPath}/datetime", data)
    # TODO message status should be required at some point
    validate_MessageStatus_field(f"{fieldPath}/status", data, required = False)
    validate_List_field(f"{fieldPath}/tags", data, custom.validate_MessageTagId, notEmpty = False)
    validate_String_field(f"{fieldPath}/text", data)
    validate_String_field(f"{fieldPath}/translation", data)

def validate_MessageDirection_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_MessageDirection(fieldPath, data[fieldName])

def validate_MessageDirection(fieldPath, value):
    if value == "MessageDirection.in":
        return
    if value == "MessageDirection.out":
        return
    raise ValidationError(f"{fieldPath} is invalid: {value}")

def validate_MessageStatus_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_MessageStatus(fieldPath, data[fieldName])

def validate_MessageStatus(fieldPath, value):
    if value == "MessageStatus.pending":
        return
    if value == "MessageStatus.confirmed":
        return
    if value == "MessageStatus.failed":
        return
    if value == "MessageStatus.unknown":
        return
    raise ValidationError(f"{fieldPath} is invalid: {value}")

def validate_SuggestedReply_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_SuggestedReply(fieldPath, data[fieldName])

def validate_SuggestedReply(fieldPath, data):
    validate_String_field(f"{fieldPath}/text", data)
    validate_String_field(f"{fieldPath}/translation", data)
    validate_String_field(f"{fieldPath}/shortcut", data, required = False)

def validate_SuggestedReply_doc(fieldPath, docId, data):
    validate_String(f"{fieldPath}/doc-id", docId, prefix = "reply-")
    validate_SuggestedReply(fieldPath, data)

def validate_Tag_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_Tag(fieldPath, data[fieldName])

def validate_Tag(fieldPath, data):
    validate_String_field(f"{fieldPath}/text", data)
    validate_TagType_field(f"{fieldPath}/type", data)
    validate_String_field(f"{fieldPath}/shortcut", data)

def validate_TagType_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_TagType(fieldPath, data[fieldName])

def validate_TagType(fieldPath, value):
    if value == "TagType.normal":
        return
    if value == "TagType.important":
        return
    raise ValidationError(f"{fieldPath} is invalid: {value}")

def validate_SystemMessage_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_SystemMessage(fieldPath, data[fieldName])

def validate_SystemMessage_doc(fieldPath, docId, data):
    validate_String(f"{fieldPath}/doc-id", docId, prefix = "sysmsg-")
    validate_SystemMessage(fieldPath, data)

def validate_SystemMessage(fieldPath, data):
    validate_String_field(f"{fieldPath}/text", data)
    validate_bool_field(f"{fieldPath}/expired", data, required = False)

# ----------------------------------------------------------------------
# Generated core type validation functions

def validate_List_field(fieldPath, data, validationMethod, required = True, notEmpty = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_List(fieldPath, data[fieldName], validationMethod, notEmpty)

def validate_List(fieldPath, valueList, validationMethod, notEmpty = True):
    if len(valueList) == 0:
        if notEmpty:
            raise ValidationError(f"{fieldPath} is empty")
    for value in valueList:
        validationMethod(fieldPath, value)

def validate_Map_field(fieldPath, data, validationMethod, required = True, notEmpty = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_Map(fieldPath, data[fieldName], validationMethod, notEmpty)

def validate_Map(fieldPath, valueMap, validationMethod, notEmpty = True):
    if len(valueMap) == 0:
        if notEmpty:
            raise ValidationError(f"{fieldPath} is empty")
    for entry in valueMap:
        validate_String(f"{fieldPath}/key", entry[0])
        validationMethod(f"{fieldPath}/value", entry[1])

def validate_bool_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_bool(fieldPath, data[fieldName])

def validate_bool(fieldPath, value):
    if value is None:
        raise ValidationError(f"{fieldPath} is undefined")
    if value == True:
        return
    if value == False:
        return
    raise ValidationError(f"{fieldPath} invalid: {value}")

def validate_DateTime_field(fieldPath, data, required = True):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_DateTime(fieldPath, data[fieldName])

def validate_DateTime(fieldPath, value):
    if value is None:
        raise ValidationError(f"{fieldPath} is undefined")
    # Apparently firebase datetime has a trailing `Z` which python does not understand
    if value.endswith("Z"):
        value = value[:-1]
    try:
        datetime.fromisoformat(value)
    except ValueError as e:
        raise ValidationError(f"{fieldPath} invalid: {value}")

def validate_String_field(fieldPath, data, required = True, notEmpty = True, prefix = None):
    fieldName = fieldPath.split('/')[-1]
    if not fieldName in data:
        if required:
            raise ValidationError(f"{fieldPath} is missing")
        return
    validate_String(fieldPath, data[fieldName], notEmpty, prefix)

def validate_String(fieldPath, value, notEmpty = True, prefix = None):
    if value is None:
        raise ValidationError(f"{fieldPath} is undefined")
    if not value:
        if notEmpty:
            raise ValidationError(f"{fieldPath} is empty")
    if prefix is None:
        return
    if value.startswith(prefix):
        return
    # print prefix to disclose hidden characters before raising an exception
    for index in range(len(prefix)):
        print(f"  char {index} : {value[index]} : {ord(value[index])}")
    raise ValidationError(f"{fieldPath} invalid: {value}")

class ValidationError(Exception):
    """Exception raised for errors in the input.

    Attributes:
        message -- explanation of the error
    """

    def __init__(self, message):
        self.message = message
