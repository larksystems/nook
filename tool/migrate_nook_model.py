from core_data_modules.logging import Logger

log = Logger(__name__)

warning_count = 0

# Migrate the object and return True
# or return False if the object has already been migrated
def migrate_Conversation(data):
    changed = False

    for elem in data["messages"]:
        if migrate_Message(elem):
            changed = True

    return changed

# Migrate the object and return True
# or return False if the object has already been migrated
def migrate_Message(data):
    changed = False

    if migrate_MessageDirection(data, "direction"):
        changed = True

    return changed

# Migrate the enum and return True
# or return False if the enum has already been migrated
def migrate_MessageDirection(data, key):
    value = data[key]

    if value == "MessageDirection.in":
        return False
    elif value == "MessageDirection.out":
        return False
    elif value == "in":
        newValue = "MessageDirection.in"
    elif value == "out":
        newValue = "MessageDirection.out"
    else:
        warning(f"Unknown MessageDirection: {value}")
        return False

    data[key] = newValue
    return True

# Migrate the object and return True
# or return False if the object has already been migrated
def migrate_SuggestedReply(data):
    changed = False


    return changed

# Migrate the object and return True
# or return False if the object has already been migrated
def migrate_Tag(data):
    changed = False

    if migrate_TagType(data, "type"):
        changed = True

    return changed

# Migrate the enum and return True
# or return False if the enum has already been migrated
def migrate_TagType(data, key):
    value = data[key]

    if value == "TagType.normal":
        return False
    elif value == "TagType.important":
        return False
    elif value == "normal":
        newValue = "TagType.normal"
    elif value == "important":
        newValue = "TagType.important"
    else:
        warning(f"Unknown TagType: {value}")
        return False

    data[key] = newValue
    return True

# Log the warning and increment the warning_count
def warning(message):
    global warning_count
    log.warning(message)
    warning_count += 1
