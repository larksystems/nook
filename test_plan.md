Navbar
  - Signed in state
    - [ ] Auth: navbar should contain user auth (profile photo, name and sign out). Sign out should kick the user to auth page.
    - [ ] User presence: when another user is using nook, you should see the other person indicator (green dot). Clicking on it should take to the conversation.
        - Test by adding an conversation id and the time stamp under user_presence > user email
    - [ ] Conversation list panel: ??
    - [ ] Style: navbar shouldn't hide any of the content below

  - Signed out state
    - [ ] Navbar should contain only signin button, should login via the first domain name

Banner
 - [ ] If the user doesn't have access to the data set, a banner should appear at the top

User permissions
 - Toggle the following flag to see the nook UI reacting to it
   - [ ] `replies_panel_visibility` should affect the suggested replies panel on the right