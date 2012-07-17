# 7/16 Notes
* A new bookmark is created for every modification you make.
* Pressing any option on the ServerList while editing mode is turned on will result in an attempted connection. It should bring up an edit screen instead.
* We need to verify that all bookmark fields are filled in before we try to connect to it. The program will crash without any indication of the failure if we don't.
* The ChatViewController's UITextField can be flicked off screen and become stuck. The only way to fix it is a hard restart of the app.

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