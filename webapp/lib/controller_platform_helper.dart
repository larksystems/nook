part of controller;

uuid.Uuid uuidGenerator = new uuid.Uuid();

String generateTagId() => 'tag-${uuidGenerator.v4().substring(0, 8)}';
