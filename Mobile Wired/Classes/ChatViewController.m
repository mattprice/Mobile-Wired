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
#import "UserInfoViewController.h"
#import "UserListViewController.h"

#import "BlockAlertView.h"
#import "BlockTextPromptAlertView.h"

@implementation ChatMessage

- (id)init
{
    self = [super init];
    if (self) {
        self.message = @"";
        self.userID = @"";
    }
    
    return self;
}

@end

@implementation ChatViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)loadConnectionSettings {
    // NSUserDefaultsDidChangeNotification doesn't let us know what changed so we tell the server
    // about anything that could have possibly updated.
    
    NSString *nick = bookmark[@"UserNick"];
    if ([nick isEqualToString:@""]) {
        nick = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserNick"];
    }
    
    NSString *status = bookmark[@"UserStatus"];
    if ([status isEqualToString:@""]) {
        status = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserStatus"];
    }
    
    [self.connection setNick:nick];
    [self.connection setStatus:status];
    [self.connection setIcon:nil];
}

- (void)dealloc
{
    // Remove any NSNotificationCenter observers, otherwise the app
    // will crash if we receive a notification after dealloc'ing.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark ViewDeck Delegate Methods

- (IIViewDeckController *)userListViewController
{
    return (IIViewDeckController *)self.viewDeckController.rightController;
}

- (void)viewDeckController:(IIViewDeckController *)viewDeckController didShowCenterViewFromSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated
{
    // Close the UserInfoView whenever the User List is closed.
    if ( viewDeckSide == IIViewDeckRightSide ) {
        [self.userListViewController closeRightView];
    }
}

#pragma mark -
#pragma mark Wired Connection Methods

- (void)new:(NSInteger)indexRow
{
    // Create the navigation bar.
    navigationBar.items = @[[[UINavigationItem alloc] init]];
    
    // Create a progress HUD.
    if (!progressHUD) {
        progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        progressHUD.delegate = self;
        [self.view addSubview:progressHUD];
    }
    
    // Initialize the message list.
    chatMessages = [NSMutableArray new];
    
    // Connect to the bookmark.
    bookmark = [[NSUserDefaults standardUserDefaults] valueForKey:@"Bookmarks"][indexRow];
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
    [self.connection connectToServer:bookmark[@"ServerHost"] onPort:[bookmark[@"ServerPort"] integerValue]];
    self.userListView.connection = self.connection;
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
    
    // Cancel
    [alert setCancelButtonWithTitle:@"Cancel" block:nil];
    
    // Set Topic
    if ( [[self.connection getMyPermissions][@"wired.account.chat.set_topic"] boolValue] ) {
        [alert addButtonWithTitle:@"Set Topic" block:^{
            BlockTextPromptAlertView *prompt = [BlockTextPromptAlertView promptWithTitle:@"Set Topic"
                                                                                 message:@""
                                                                             defaultText:self->serverTopic];
            
            // Set Topic: Cancel
            [prompt setCancelButtonWithTitle:@"Cancel" block:nil];
            
            // Set Topic: Save
            __block BlockTextPromptAlertView *blockPrompt = prompt;
            [prompt setCancelButtonWithTitle:@"Save" block:^{
                [self.connection setTopic:blockPrompt.textField.text forChannel:@"1"];
            }];
            
            // By default, the text field is set to auto-capitalize each word.
            prompt.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            
            [prompt show];
        }];
    }
    
    // Send Broadcast
    if ( [[self.connection getMyPermissions][@"wired.account.message.broadcast"] boolValue] ) {
        [alert addButtonWithTitle:@"Send Broadcast" block:^{
            BlockTextPromptAlertView *prompt = [BlockTextPromptAlertView promptWithTitle:@"Send Broadcast"
                                                                                 message:@""
                                                                             defaultText:@""];
            
            // Broadcast: Cancel
            [prompt setCancelButtonWithTitle:@"Cancel" block:nil];
            
            // Broadcast: Send
            __block BlockTextPromptAlertView *blockPrompt = prompt;
            [prompt setCancelButtonWithTitle:@"Send" block:^{
                [self.connection sendBroadcast:blockPrompt.textField.text];
            }];
            
            // By default, the text field is set to auto-capitalize each word.
            prompt.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            
            [prompt show];
        }];
    }
    
    [alert show];
}

#pragma mark -
#pragma mark UITableView Helper Methods

- (void)addMessageToView:(NSString *)message fromID:(NSString *)userID
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = message;
    newMessage.userID = userID;
    
    [chatMessages addObject:newMessage];
    [chatTableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[chatMessages count]-1 inSection:0];
    [chatTableView scrollToRowAtIndexPath:indexPath
                         atScrollPosition:UITableViewScrollPositionBottom
                                 animated:YES];
}

- (void)addEmoteToView:(NSString *)emote fromID:(NSString *)userID
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = emote;
    newMessage.userID = userID;
    
    [chatMessages addObject:newMessage];
    [chatTableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[chatMessages count]-1 inSection:0];
    [chatTableView scrollToRowAtIndexPath:indexPath
                         atScrollPosition:UITableViewScrollPositionBottom
                                 animated:YES];
}

- (void)addSystemMessageToView:(NSString *)message
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = message;
    
    [chatMessages addObject:newMessage];
    [chatTableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[chatMessages count]-1 inSection:0];
    [chatTableView scrollToRowAtIndexPath:indexPath
                         atScrollPosition:UITableViewScrollPositionBottom
                                 animated:YES];
}

#pragma mark -
#pragma mark UITableView Data Sources

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [chatMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Setting the numberOfLines to 0 means the UILabel will use as many lines as necessary.
    cell.detailTextLabel.numberOfLines = 0;
    
    ChatMessage *message = chatMessages[[indexPath row]];
    NSDictionary *currentUser = [self.connection userList][@"1"][message.userID];
    UIImage *userImage = [UIImage imageWithData:currentUser[@"wired.user.icon"]];
    
    // Make the user image into a circle.
//    UIGraphicsBeginImageContextWithOptions(userImage.size, NO, 0);
//    [[UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, userImage.size} cornerRadius:15.0] addClip];
//    [userImage drawInRect:(CGRect){CGPointZero, userImage.size}];
//    userImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    cell.detailTextLabel.text = message.message;
    cell.imageView.image = userImage;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatMessage *message = chatMessages[[indexPath row]];
    UILabel *label = [UILabel new];
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:label.font, NSFontAttributeName, nil];

    CGRect frame = [message.message boundingRectWithSize:CGSizeMake(tableView.frame.size.width, 20000.0)
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:attributesDictionary
                                      context:nil];
    
    // Animate the height of the UITableViewCell.
//    [tableView beginUpdates];
//    [tableView endUpdates];
    
    // User icons are 32px. With 5px of top and bottom padding, the minimum cell height should be 42.
    return (frame.size.height > 42) ? frame.size.height : 42;
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
    [[navigationBar topItem] setTitle:self.connection.serverInfo[@"wired.info.name"]];
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cog.png"]
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(openOptionsMenu)];
    
    // Update the progress HUD.
    progressHUD.labelText = @"Logging In";
    
    [self loadConnectionSettings];
    [self.connection sendLogin:bookmark[@"UserLogin"] withPassword:bookmark[@"UserPass"]];
}

/*
 * Received information about a user.
 *
 * This method is called when we receive specifically requested information about a user.
 *
 */
- (void)didReceiveUserInfo:(NSDictionary *)info
{
    UserInfoViewController *infoController = [[UserInfoViewController alloc] initWithNibName:@"UserInfoView"
                                                                                      bundle:nil
                                                                                    userInfo:info];
    
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
    NSString *message = [NSString stringWithFormat:@"<<< Connected to %@ >>>\n",
                         self.connection.serverInfo[@"wired.info.name"]];
    [self addSystemMessageToView:message];
    
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
    NSString *message = [NSString stringWithFormat:@"<<< Disconnected from %@ >>>\n",
                         self.connection.serverInfo[@"wired.info.name"]];
    [self addSystemMessageToView:message];
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
    NSString *message = [NSString stringWithFormat:@"<<< Disconnected from %@ >>>\n",
                         self.connection.serverInfo[@"wired.info.name"]];
    [self addSystemMessageToView:message];
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
    NSString *message = [NSString stringWithFormat:@"<<< Reconnecting to %@ in %@ seconds >>>\n",
                         self.connection.serverInfo[@"wired.info.name"], delay];
    [self addSystemMessageToView:message];
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
    NSString *message = [NSString stringWithFormat:@"<<< Disconnected from %@:%@ >>>\n",
                         self.connection.serverInfo[@"wired.info.name"], error.description];
    [self addSystemMessageToView:message];
    
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
    NSString *message = [NSString stringWithFormat:@"<<< Reconnected to %@ >>>\n",
                         self.connection.serverInfo [@"wired.info.name"]];
    [self addSystemMessageToView:message];
    
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
        NSLog(@"Channel #%@ topic: %@ (set by %@)", channel, topic, nick);
#endif
    }
    
    // Subsequent topic changes, so we should notify the user.
    else {
#ifdef DEBUG
        NSLog(@"%@ | <<< %@ changed topic to '%@' >>>", channel, nick, topic);
#endif
        
        NSString *message = [NSString stringWithFormat:@"<<< %@ changed topic to %@ >>>\n", nick, topic];
        [self addSystemMessageToView:message];
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
    NSLog(@"%@ | %@ (%@) : %@", channel, nick, userID, message);
#endif
    
    [self addMessageToView:message fromID:userID];
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
    if (userID == [self.connection myUserID])
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
    NSLog(@"%@ (%@) : %@", nick, userID, message);
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
    NSLog(@"%@ | %@ (%@) %@", channel, nick, userID, message);
#endif
    
    
    [self addEmoteToView:message fromID:userID];
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
    NSLog(@"<<< %@ has joined >>>", nick);
#endif
    
    NSString *message = [NSString stringWithFormat:@"<<< %@ has joined >>>\n", nick];
    [self addSystemMessageToView:message];
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
    NSLog(@"<<< %@ is now known as %@ >>>", oldNick, newNick);
#endif
    
    NSString *message = [NSString stringWithFormat:@"<<< %@ is now known as %@ >>>\n", oldNick, newNick];
    [self addSystemMessageToView:message];
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
    NSLog(@"<<< %@ has left >>>", nick);
#endif
    
    NSString *message = [NSString stringWithFormat:@"<<< %@ has left >>>\n", nick];
    [self addSystemMessageToView:message];
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
    NSLog(@"<<< %@ was kicked by %@ (%@) >>>", nick, kicker, reason);
#endif
    
    NSString *message;
    if ([reason isEqualToString:@""]) {
        message = [NSString stringWithFormat:@"<<< %@ was kicked by %@ >>>\n", nick, kicker];
    } else {
        message = [NSString stringWithFormat:@"<<< %@ was kicked by %@ (%@) >>>\n", nick, kicker, reason];
    }
    
    [self addSystemMessageToView:message];
    
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
    [self.userListView setUserList:userList];
    [self.userListView.mainTableView setNeedsDisplay];
}

#pragma mark -
#pragma mark Sliding Keyboard Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Register to listen for NSUserDefaults changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadConnectionSettings)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    // Enable sliding to see the user list.
    IIViewDeckController *rightView = (IIViewDeckController *)self.viewDeckController.rightController;
    rightView.centerController = self.userListView;
    
    // Register an event for when a keyboard pops up.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove any NSNotificationCenter observers, otherwise the app
    // will crash if we receive a notification after dealloc'ing, or
    // when swapping to another view.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Disable panning view while typing.
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Re-enable panning of view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    // Move the textField out of the keyboard's way.
    // TODO: This animation doesn't match the keyboard's animation perfectly.
    [UIView animateWithDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0
                        options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^{
                         CGRect keyboardFrame = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
                         
                         self->accessoryView.frame = CGRectMake(0.0,
                                                                keyboardFrame.origin.y - 44,
                                                                self->accessoryView.frame.size.width,
                                                                self->accessoryView.frame.size.height);
                         
                         self->chatTableView.frame = CGRectMake(self->chatTableView.frame.origin.x,
                                                                self->chatTableView.frame.origin.y,
                                                                self->chatTableView.frame.size.width,
                                                                self->accessoryView.frame.origin.y - 45);
                         
                         // Scroll to bottom of chatTableView.
                         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self->chatMessages count]-1 inSection:0];
                         [self->chatTableView scrollToRowAtIndexPath:indexPath
                                                    atScrollPosition:UITableViewScrollPositionBottom
                                                            animated:YES];
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    // Adjust the accessory view.
    [UIView animateWithDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0
                        options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^{
                         // Pan the accessory view down.
                         self->accessoryView.frame = CGRectMake(0.0,
                                                                [[UIScreen mainScreen] bounds].size.height - 44,
                                                                self->accessoryView.frame.size.width,
                                                                self->accessoryView.frame.size.height);
                         
                         // Resize the chat view.
                         self->chatTableView.frame = CGRectMake(self->chatTableView.frame.origin.x,
                                                                self->chatTableView.frame.origin.y,
                                                                self->chatTableView.frame.size.width,
                                                                self->accessoryView.frame.origin.y - 45);
                         
                         // Scroll to bottom of chatTableView.
                         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self->chatMessages count]-1 inSection:0];
                         [self->chatTableView scrollToRowAtIndexPath:indexPath
                                                    atScrollPosition:UITableViewScrollPositionBottom
                                                            animated:YES];
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

@end
