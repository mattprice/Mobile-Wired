//
//  ChatViewController.m
//  Mobile Wired
//
//  Copyright (c) 2012 Matthew Price, http://mattprice.me/
//  Copyright (c) 2012 Ember Code, http://embercode.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "ChatViewController.h"
#import "IIViewDeckController.h"
#import "UserListViewController.h"
#import "UserInfoViewController.h"

#import "BlockAlertView.h"
#import "BlockTextPromptAlertView.h"

@interface ChatViewController (private)
    - (void)animateKeyboardReturnToOriginalPosition;
    - (void)animateKeyboardOffscreen;
@end

@implementation ChatViewController

@synthesize connection = _connection;
@synthesize userListView, badgeCount;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create UIGestureRecognizer for sliding the keyboard down.
    // This gets removed once the keyboard disappears.
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panRecognizer.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark ViewDeck Delegate Methods
- (BOOL)viewDeckControllerWillCloseRightView:(IIViewDeckController *)viewDeckController animated:(BOOL)animated
{
    // Close the UserInfoView whenever the User List is closed.
    [(IIViewDeckController *)self.viewDeckController.rightController closeRightView];
    
    return YES;
}

#pragma mark -
#pragma mark Wired Connection Methods

- (void)new:(NSInteger)indexRow
{
    // Create the navigation bar.
    navigationBar.items = [NSArray arrayWithObject:[[UINavigationItem alloc] init]];
    
    // Create a progress HUD.
    if (!progressHUD) {
        progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        progressHUD.delegate = self;
        [self.view addSubview:progressHUD];
    }
    
    // Connect to the bookmark.
    bookmark = [[[NSUserDefaults standardUserDefaults] valueForKey:@"Bookmarks"] objectAtIndex:indexRow];
    [self connect];
}

- (Boolean)isConnected
{
    if (self.connection) {
        return self.connection.isConnected;
    } else {
        return 0;
    }
}

- (void)connect
{
    // Update the progress HUD.
    progressHUD.mode = MBProgressHUDModeIndeterminate;
    progressHUD.animationType = MBProgressHUDAnimationZoom;
    progressHUD.labelText = @"Connecting";
    [progressHUD show:YES];
    
    // Create a new WiredConnection.
    self.connection = [[WiredConnection alloc] init];
    self.connection.delegate = self;
    [self.connection connectToServer:[bookmark valueForKey:@"ServerHost"] onPort:[[bookmark valueForKey:@"ServerPort"] integerValue]];
}

- (void)disconnect
{
    // Disconnect from the server.
    // This will invoke the didDisconnect delegate method.
    [self.connection disconnect];
}


#pragma mark -
#pragma mark UI Actions
- (IBAction)sendButtonPressed:(id)sender
{
    // Send the message.
    [self.connection sendChatMessage:chatTextField.text toChannel:@"1"];
    chatTextField.text = @"";
    
    [TestFlight passCheckpoint:@"Sent Chat Message (Button)"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Send the message.
    [self.connection sendChatMessage:chatTextField.text toChannel:@"1"];
    chatTextField.text = @"";
    
    [TestFlight passCheckpoint:@"Sent Chat Message (Keyboard)"];
    
    return YES;
}

- (void)getInfoForUser:(NSString *)userID
{
    [self.connection getInfoForUser:userID];
}

- (void)openOptionsMenu
{
    // Dismiss the keyboard.
    [self.view endEditing:YES];
    
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Connection Options" message:@""];
    
    // Disconnect
    [alert setDestructiveButtonWithTitle:@"Disconnect" block:^{
        [self disconnect];
    }];
    
    // Close
    [alert setCancelButtonWithTitle:@"Cancel" block:nil];
    
    // Set Topic
    // TODO: Need to see if you have permission to change the topic.
    [alert addButtonWithTitle:@"Set Topic" block:^{
        BlockTextPromptAlertView *prompt = [BlockTextPromptAlertView promptWithTitle:@"Set Topic"
                                                                             message:@""
                                                                         defaultText:serverTopic];
        
        // Set Topic: Cancel
        [prompt setCancelButtonWithTitle:@"Cancel" block:nil];
        
        // Set Topic: Save
        __weak BlockTextPromptAlertView *weakPrompt = prompt;
        [prompt setCancelButtonWithTitle:@"Save" block:^{
            [self.connection setTopic:weakPrompt.textField.text forChannel:@"1"];
        }];
        
        // By default, the text field is set to auto-capitalize each word.
        prompt.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        
        [prompt show];
    }];
    
    // Send Broadcast
    // TODO: Need to see if you have permission to send broadcasts.
    [alert addButtonWithTitle:@"Send Broadcast" block:^{
        BlockTextPromptAlertView *prompt = [BlockTextPromptAlertView promptWithTitle:@"Send Broadcast"
                                                                             message:@""
                                                                         defaultText:@""];
        
        // Broadcast: Cancel
        [prompt setCancelButtonWithTitle:@"Cancel" block:nil];
        
        // Broadcast: Send
        __weak BlockTextPromptAlertView *weakPrompt = prompt;
        [prompt setCancelButtonWithTitle:@"Send" block:^{
            [self.connection sendBroadcast:weakPrompt.textField.text];
        }];
        
        // By default, the text field is set to auto-capitalize each word.
        prompt.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        
        [prompt show];
    }];
    
    [alert show];
}

#pragma mark -
#pragma mark Wired Delegate Methods

/*
 * Connection to server was successful.
 *
 * The server requires a login, nick, status, or icon after sending us its life story.
 * The specs suggest sending the nick/status/icon before sending the login info, but
 * any order we want would technically work.
 *
 */
- (void)didReceiveServerInfo:(NSDictionary *)serverInfo
{
    // Customize the bar title and buttons.
    [navigationBar setTitle:[self.connection.serverInfo objectForKey:@"wired.info.name"]];
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cog.png"]
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(openOptionsMenu)];
    
    // Update the progress HUD.
    progressHUD.labelText = @"Logging In";
    
    [self.connection setNick:[[NSUserDefaults standardUserDefaults] stringForKey:@"UserNick"]];
    [self.connection setIcon:nil];
    [self.connection setStatus:[[NSUserDefaults standardUserDefaults] stringForKey:@"UserStatus"]];
    [self.connection sendLogin:[bookmark valueForKey:@"UserLogin"] withPassword:[bookmark valueForKey:@"UserPass"]];
}

/*
 * Received information about a user.
 *
 * This method is called when we receive specifically requested information about a user.
 *
 */
- (void)didReceiveUserInfo:(NSDictionary *)info
{
    UserInfoViewController *infoController = [[UserInfoViewController alloc] initWithNibName:@"UserInfoView" bundle:nil userInfo:info];

    // Nested ViewDeckControllers!
    // This controller already exists (AppDelegate.m) but we need to set up its right-most view.
    IIViewDeckController *rightView = (IIViewDeckController *)self.viewDeckController.rightController;
    rightView.rightController = infoController;
    rightView.rightSize = 66;
    [rightView openRightViewAnimated:YES];
}

/*
 * Login to the server was successful.
 *
 * The server doesn't actually require us to send anything next, so we can really do
 * anything that we want. Download a file, join a channel, play with ourselves...
 *
 */
- (void)didLoginSuccessfully
{
    progressHUD.labelText = @"Joining Channel";
    
    [self.connection joinChannel:@"1"];
}

/*
 * Login to the server failed.
 *
 * This method is called if the user is banned or their username and password combination
 * is incorrect. The reason returned is not a complete sentence.
 *
 */
- (void)didFailLoginWithReason:(NSString *)reason
{
    // Update the progress HUD.
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Login Failed";
    progressHUD.detailsLabelText = reason;
}

/*
 * Connection and login was successful.
 *
 * Called on first connection to the Wired server once the user is finally able to perform actions.
 *
 */
- (void)didConnectAndLoginSuccessfully
{
    // Update the progress HUD.
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Connected";
    [progressHUD hide:YES afterDelay:2];
    
    // Report the connection to chat.
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< Connected to %@ >>>\n",[self.connection.serverInfo objectForKey:@"wired.info.name"]];
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    
    [TestFlight passCheckpoint:@"Connected to Server"];
}

/*
 * Connection to the server failed.
 *
 * This method is called if the socket connection is not successful. The NSError sent is the
 * same NSError returned by GCDAsyncSocket. We do not yet attempt to parse the NSError.
 * Assume that the host/port is incorrect, or that the Wired server is currently offline.
 *
 */
- (void)didFailConnectionWithReason:(NSError *)error
{
    // Update the progress HUD.
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Connection Failed";
}

/*
 * Disconnected from the Wired server.
 *
 * This method is called when the user disconnects from the Wired server and we do not expect
 * to reconnect.
 *
 */
- (void)didDisconnect
{
    // Update the progress HUD.
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Disconnected";
    [progressHUD show:YES];
    
    // Report the disconnect to chat.
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< Disconnected from %@ >>>\n",[self.connection.serverInfo objectForKey:@"wired.info.name"]];
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * Reconnecting to the Wired server.
 *
 * This method is called when a user unexpectedly disconnects from the server and we are in the
 * process of reconnecting. This will most likely occur if the user is kicked.
 *
 */
- (void)willReconnect
{
    // Update the Progress HUD
    progressHUD.mode = MBProgressHUDModeIndeterminate;
    progressHUD.labelText = @"Reconnecting";
    [progressHUD show:YES];
    
    // Report the disconnect to chat.
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< Disconnected from %@ >>>\n",[self.connection.serverInfo objectForKey:@"wired.info.name"]];
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * Reconnecting to the Wired server.
 *
 * This method is called when a user expectedly disconnects from the server and we are in the
 * process of reconnecting. This will most likely occur if the server crashed and we're waiting
 * a few seconds for it to restart.
 *
 */
- (void)willReconnectDelayed:(NSString *)delay
{
    // Report the disconnect to chat.
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< Reconnecting to %@ in %@ seconds >>>\n",[self.connection.serverInfo objectForKey:@"wired.info.name"], delay];
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];   
}

/*
 * Reconnecting to the Wired server.
 *
 * This method is called when a user expectedly disconnects from the server and we are in the
 * process of reconnecting. This will most likely occur if the server crashed and we're waiting
 * a few seconds for it to restart. An error is sent when this is not our first reconnection try.
 *
 */
- (void)willReconnectDelayed:(NSString *)delay withError:(NSError *)error
{
    // Report the disconnect to chat.
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< Disconnected from %@:%@ >>>\n",[self.connection.serverInfo objectForKey:@"wired.info.name"], error.description];
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    
    [self willReconnectDelayed:delay];
}

/*
 * Reconnected to the Wired server.
 *
 * This method is called once the server reconnects from a willReconnect scenario.
 *
 */
- (void)didReconnect
{
    // Update the Progress HUD
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Reconnected";
    [progressHUD hide:YES afterDelay:2];
    
    // Report the disconnect to chat.
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< Reconnected to %@ >>>\n",[self.connection.serverInfo objectForKey:@"wired.info.name"]];
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    
    [TestFlight passCheckpoint:@"Reconnected to Server"];
}

/*
 * Received channel topic from server.
 *
 * Occurs on first joining the channel and on each time the topic is changed thereafter.
 * Only the subsequent changes should notify the user that the topic has changed.
 *
 */
- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel
{
    // Initial connection.
    if (serverTopic == nil || [topic isEqualToString:@""]) {
#ifdef DEBUG
        NSLog(@"Channel #%@ topic: %@ (set by %@)",channel,topic,nick);
#endif
    }

    // Subsequent topic changes, so we should notify the user.
    else {
#ifdef DEBUG
        NSLog(@"%@ | <<< %@ changed topic to '%@' >>>",channel,nick,topic);
#endif

        NSMutableString *chatText = [chatTextView.text mutableCopy];
        
        [chatText appendFormat:@"<<< %@ changed topic to %@ >>>\n",nick,topic];
        
        chatTextView.text = chatText;
        [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    }

    serverTopic = topic;
}

/*
 * Received chat message for a channel.
 *
 * Message could be from anyone, including yourself.
 *
 */
- (void)didReceiveChatMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
#ifdef DEBUG
    NSLog(@"%@ | %@ (%@) : %@",channel,nick,userID,message);
#endif
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    
    [chatText appendFormat:@"%@: %@\n",nick,message];
    
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * Received a private message from some user.
 *
 * Message could be from anyone, including yourself. Be sure not to send a push notification
 * if the message was from yourself.
 *
 */
- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
#ifdef DEBUG
    NSLog(@"%@ (%@) : %@",nick,userID,message);
#endif
    
    // Don't send notification if message is from yourself.
    if (userID == [connection myUserID])
        return;
    
    NSString *tMessage = [NSString stringWithFormat:@"%@: %@", nick, message];
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Message Recevied" message:tMessage];
    [alert setCancelButtonWithTitle:@"Close" block:^{}];
    [alert show];
}

/*
 * Received a broadcast from someone.
 *
 * Broadcast could be from anyone, including yourself.
 *
 */
- (void)didReceiveBroadcast:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
#ifdef DEBUG
    NSLog(@"%@ (%@) : %@",nick,userID,message);
#endif
    
    NSString *tMessage = [NSString stringWithFormat:@"%@: %@", nick, message];
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Broadcast Received" message:tMessage];
    [alert setCancelButtonWithTitle:@"Close" block:^{}];
    [alert show];
}

/*
 * Received an emote for a channel.
 *
 * Emote could be from anyone, including yourself.
 *
 */
- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
#ifdef DEBUG
    NSLog(@"%@ | %@ (%@) %@",channel,nick,userID,message);
#endif
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    
    [chatText appendFormat:@"*** %@ %@\n",nick,message];
    
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * User joined a channel.
 *
 * Join notifications will only be about other users.
 *
 */
- (void)userJoined:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
#ifdef DEBUG
    NSLog(@"<<< %@ has joined >>>",nick);
#endif
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    
    [chatText appendFormat:@"<<< %@ has joined >>>\n",nick];
    
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * User changed their nick.
 *
 * Notification could be about anyone, including yourself.
 *
 */
- (void)userChangedNick:(NSString *)oldNick toNick:(NSString *)newNick forChannel:(NSString *)channel
{
#ifdef DEBUG
    NSLog(@"<<< %@ is now known as %@ >>>",oldNick,newNick);
#endif
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    
    [chatText appendFormat:@"<<< %@ is now known as %@ >>>\n",oldNick,newNick];
    
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];    
}

/*
 * User left a channel.
 *
 * Leave notifications will only be about other users.
 *
 */
- (void)userLeft:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
#ifdef DEBUG
    NSLog(@"<<< %@ has left >>>",nick);
#endif
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    
    [chatText appendFormat:@"<<< %@ has left >>>\n",nick];
    
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * User was kicked from a channel.
 *
 * Kick notification could be for anyone, including yourself. If you're the user kicked, and you
 * want to rejoin the channel, then you should do so in this method. WiredConnection will not
 * rejoin for you. Also, the reason may be blank. Be sure to handle that.
 *
 * NOTE: Right now we assume that the user wants to rejoin the channel.
 *
 */
- (void)userWasKicked:(NSString *)nick withID:(NSString *)userID byUser:(NSString *)kicker forReason:(NSString *)reason forChannel:(NSString *)channel
{
#ifdef DEBUG
    NSLog(@"<<< %@ was kicked by %@ (%@) >>>",nick,kicker,reason);
#endif
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];

    if ([reason isEqualToString:@""]) {
        [chatText appendFormat:@"<<< %@ was kicked by %@ >>>\n",nick,kicker];
    } else {
        [chatText appendFormat:@"<<< %@ was kicked by %@ (%@) >>>\n",nick,kicker,reason];        
    }
    
    chatTextView.text = chatText;
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    
    // Rejoin the channel if we were the one kicked.
    if ([userID isEqualToString:self.connection.myUserID]) {
        [self willReconnect];
        [self.connection joinChannel:@"1"];
    }
}

/*
 * Received an updated user list.
 *
 * This method is called each time we receive an updated user list. Individual event notifications
 * should be handled elsewhere.
 *
 */
- (void)setUserList:(NSDictionary *)userList forChannel:(NSString *)channel
{
    [userListView setUserList:userList];
    [userListView.tableView setNeedsDisplay];
}

#pragma mark -
#pragma mark Sliding Keyboard Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Enable sliding to see the user list.
    IIViewDeckController *rightView = (IIViewDeckController *)self.viewDeckController.rightController;
    rightView.centerController = self.userListView;
    
    // Be sure we know which keyboard is selected.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textfieldWasSelected:)
                                                 name:UITextFieldTextDidBeginEditingNotification
                                               object:nil];
    
    // Register an event for when a keyboard pops up.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Add the UIGestureRecognizer to the view.
    [self.view addGestureRecognizer:panRecognizer];
    
    // Disable panning view while typing.
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Remove the UIGestureRecognizer so that you can swipe left/right again.
    [self.view removeGestureRecognizer:panRecognizer];
    
    // Re-enable panning of view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
}

- (void)textfieldWasSelected:(NSNotification *)notification
{
    chatTextField = notification.object;
    
    // Move the textField out of the keyboard's way.
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         accessoryView.frame = CGRectMake(0.0,
                                                          200.0,
                                                          accessoryView.frame.size.width,
                                                          accessoryView.frame.size.height);
                         chatTextView.frame = CGRectMake(chatTextView.frame.origin.x,
                                                         chatTextView.frame.origin.y,
                                                         chatTextView.frame.size.width,
                                                         155.0);
                         [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    // We have to hide the keyboard to remove the animation for it sliding down.
    // This is where we start displaying it again.
    keyboard.hidden = NO;
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (keyboard)
        return;
    
    // We can't access the UIKeyboard through the SDK we have to use a UIView.
    // See discussion http://www.iphonedevsdk.com/forum/iphone-sdk-development/6573-howto-customize-uikeyboard.html
    NSArray *windowList = [[UIApplication sharedApplication] windows];
    for (int k = 0; k < [windowList count]; k++) {
        UIWindow *tempWindow = [windowList objectAtIndex:k];
        for (int i = 0; i < [tempWindow.subviews count]; i++) {
            UIView *possibleKeyboard = [tempWindow.subviews objectAtIndex:i];
            if([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES) {
                keyboard = possibleKeyboard;
                return;
            }
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    // Adjust the accessory view.
    [self animateKeyboardOffscreen];
}

- (void)adjustAccessoryView
{
    // Pan the accessory view up/down.
    accessoryView.frame = CGRectMake(0.0,
                                     keyboard.frame.origin.y - 64,
                                     accessoryView.frame.size.width,
                                     accessoryView.frame.size.height);
    
    // Lengthen the chat view.
    chatTextView.frame = CGRectMake(chatTextView.frame.origin.x,
                                    chatTextView.frame.origin.y,
                                    chatTextView.frame.size.width,
                                    accessoryView.frame.origin.y - 45);
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.view];
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        originalKeyboardY = keyboard.frame.origin.y;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (velocity.y > 0) {
            [self animateKeyboardOffscreen];
        } else{
            [self animateKeyboardReturnToOriginalPosition];
        }
        return;
    }
    
    CGFloat spaceAboveKeyboard = self.view.bounds.size.height - (keyboard.frame.size.height + chatTextField.frame.size.height) + 20.0f;
    if (location.y < spaceAboveKeyboard ) {
        return;
    }
    
    CGRect newFrame = keyboard.frame;
    CGFloat newY = originalKeyboardY + (location.y - spaceAboveKeyboard);
    newY = MAX(newY, originalKeyboardY);
    newFrame.origin.y = newY;
    [keyboard setFrame: newFrame];
    [self adjustAccessoryView];
}

- (void)animateKeyboardOffscreen
{
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Pan the keyboard up/down.
                         CGRect newFrame = keyboard.frame;
                         newFrame.origin.y = keyboard.window.frame.size.height;
                         [keyboard setFrame: newFrame];
                         [self adjustAccessoryView];
                     }
     
                     completion:^(BOOL finished){
                         keyboard.hidden = YES;
                         [chatTextField resignFirstResponder];
                     }];
}

- (void)animateKeyboardReturnToOriginalPosition
{
    [UIView beginAnimations:nil context:NULL];
    
    // Pan the keyboard up/down.
    CGRect newFrame = keyboard.frame;
    newFrame.origin.y = originalKeyboardY;
    [keyboard setFrame: newFrame];
    [self adjustAccessoryView];
    
    [UIView commitAnimations];
}

@end
