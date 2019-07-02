import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

client = None

def init_client(crypto_token_path):
    global client
    cred = credentials.Certificate(crypto_token_path)
    firebase_admin.initialize_app(cred)
    client = firestore.client()

def get_message_tags():
    tags = []
    for tag in client.collection(f'messageTags').get():
        tag_dict = tag.to_dict()
        tag_dict["id"] = tag.id
        tags.append(tag_dict)
    return tags

def set_message_tag(tag_id, text, type, shortcut):
    message_tag_ref = client.document(f'messageTags/{tag_id}')
    message_tag_ref.set(
        {
            "text" : text,
            "type" : type,
            "shortcut" : shortcut
        }
    )

def get_conversation_tags():
    tags = []
    for tag in client.collection(f'conversationTags').get():
        tag_dict = tag.to_dict()
        tag_dict["id"] = tag.id
        tags.append(tag_dict)
    return tags

def set_conversation_tag(tag_id, text, type, shortcut):
    conversation_tag_ref = client.document(f'conversationTags/{tag_id}')
    conversation_tag_ref.set(
        {
            "text" : text,
            "type" : type,
            "shortcut" : shortcut
        }
    )

def get_suggested_replies():
    replies = []
    for reply in client.collection(f'suggestedReplies').get():
        reply_dict = reply.to_dict()
        reply_dict["id"] = reply.id
        replies.append(reply_dict)
    return replies

def set_suggested_reply(reply_id, text, translation, shortcut):
    conv_tag_ref = client.document(f'suggestedReplies/{reply_id}')
    conv_tag_ref.set(
        {
            "text" : text,
            "translation" : translation,
            "shortcut" : shortcut
        }
    )

def get_conversations():
    conversations = {}
    for conversation in client.collection("nook_conversations").get():
        id = conversation.id
        
        conversation_snapshot = client.document(f"nook_conversations/{id}").get()
        conversations[id] = conversation_snapshot.to_dict()
    
    return conversations

def set_conversations(conversation_map):
    for id in conversation_map.keys():
        client.document(f"nook_conversations/{id}").set(
            conversation_map[id]
        )

