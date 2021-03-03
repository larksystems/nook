# Navbar
  - Signed in state
    - [ ] Auth: Nav bar should contain user auth (profile photo, name, and sign out). Sign out should kick the user to the authentication page.
    - [ ] User presence: when another user concurrently uses nook, the person indicator (colored dots) appears. Clicking on them should take to the respective conversation.
        - Test by adding a conversation id and the time stamp under `user_presence > user email`
    - [ ] Conversation list panel: A dropdown appears when there are more than 1 conversation shards present.
	- If the test project doesn't already have 2 shards, test by setting the field `nook_conversation_shards > shard-0 > num_shards: 2` and adding a second conversation shard with a name `nook_conversation_shards > shard-1 > name: "Conversation list #2"`
    - [ ] Style: Nav bar shouldn't hide any of the content below

  - Signed out state
    - [ ] Navbar should contain only sign-in button, should log in via the first domain name

# Banner
 - [ ] If the user doesn't have access to the data set, a banner should appear at the top
   - [ ] Test by removing your email address from the `users` collection in firebase

# User permissions
 - Toggle the following flag to see the nook UI reacting to it
   - [ ] `replies_panel_visibility` should toggle suggested replies section on the right. If the `edit_notes_enabled` is `true`, the notes text area should take up the whole height of the sidebar.
   - [ ] `edit_notes_enabled` should toggle the notes text area.
   - [ ] if both `replies_panel_visibility` and `edit_notes_enabled` are `false`, the whole sidebar panel should not be visible.

# Conversation list
- User presence: when another user concurrently uses nook, the person indicator (colored dots) appears against the conversation.
  - Test by adding a conversation id and the time stamp under `user_presence > user email`
