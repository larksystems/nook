# Navbar
  - Signed in state
    - [ ] Auth: Nav bar should contain user auth (profile photo, name, and sign out). Sign out should kick the user to the authentication page.
    - [ ] User presence: when another user concurrently uses nook, the person indicator (colored dots) appears. Clicking on them should take to the respective conversation.
        - Test by adding a conversation id and the time stamp under `user_presence > user email`
    - [ ] Conversation list panel: A dropdown appears when there are more than 1 conversation shards present.
	- Test by adding a conversation name in firebase under `nook_conversation_shards > shard-n > name (field), conversations (collection)`
    - [ ] Style: Nav bar shouldn't hide any of the content below

  - Signed out state
    - [ ] Navbar should contain only sign-in button, should log in via the first domain name

# Banner
 - [ ] If the user doesn't have access to the data set, a banner should appear at the top

# User permissions
 - Toggle the following flag to see the nook UI reacting to it
   - [ ] `replies_panel_visibility` should toggle suggested replies section on the right. If the `edit_notes_enabled` is present, the notes text area should take up the whole height of the sidebar.
   - [ ] `edit_notes_enabled` should toggle the notes text area.
   - [ ] if both `replies_panel_visibility` and `edit_notes_enabled` are `false`, the whole sidebar panel should not be visible.

# Conversation list
- User presence: when another user concurrently uses nook, the person indicator (colored dots) appears against the conversation.
  - Test by adding a conversation id and the time stamp under `user_presence > user email`
