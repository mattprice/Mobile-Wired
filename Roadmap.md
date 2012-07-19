# 7/19 Notes
* Display an alert if all bookmark fields are not filled in before we try to connect to it.
* Display an alert if someone tries to edit a bookmark while it's connected.
* Need to display connection images.
* The ChatViewController's UITextField can be flicked off screen and become stuck. The only way to fix it is a hard restart of the app.
    * After sending a message, you are not allowed to swipe to the server or user list. Attempting to will result in the keyboard flying offscreen.
* If possible, fix UITableView background color on iOS 6.

# Version 1
* TestFlight SDK (?)
* Features:
    * Add viewing of broadcasts
    * Add viewing of server topic
    * Add ability to view user info
    * Add ability to send and receive PMs
* Improvements:
   * Display a disclosure triangle while editing the server list so that it's more obvious they're selectable.
   * When selecting text/link, keyboard disappears before the text field moves down.
   * Improve animations when resizing UITableViews (ex, BookmarkView and ChatView).
   * Text field does not expand with long messages.
   * <<< Notification messages >>> should be colored red.

# Version 1.x
* SSL connection
* Landscape mode
* Local notifications for PMs or if incoming chat message has highlighted keywords
* Improve connection error messages

# Feature Ideas
* Ability to send attachments to chat (CloudApp?)
* iPad support