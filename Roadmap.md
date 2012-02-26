# WiredConnection Improvements
* Reconnect if disconnected or kicked
    * Add a lastActivity timeout to recognize server-side disconnect
* Show nick changes in chat
* Does not catch connection issues if the server info is wrong

# Version 1
* Features:
    * Connect the user button
    * Add viewing of broadcasts
    * Add viewing of server topic
    * Add connection status messages
    * Implement server bookmarks
* Fixes
	* Don't send "has joined" messages when first receiving the user list.
    * Icons in the user list are fuzzy. Manually resize them with code.
    * The user icon for Mobile Wired users doesn't appear
    * Text selection causes the keyboard to disappear, but the chatTextField doesn't move down

# Version 1.x
* SSL connection
* Landscape mode
* Local notifications for PMs or if incoming chat message has highlighted keywords

# Feature Ideas
* Ability to send attachments to chat (CloudApp?)
* iPad support