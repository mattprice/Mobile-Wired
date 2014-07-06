//
//  MWChatViewController.m
//  Mobile Wired
//
//  Copyright (c) 2014 Matthew Price, http://mattprice.me/
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

#import "MWChatViewController.h"

#import "MWChatMessageCell.h"
#import "MWUserInfoViewController.h"
#import "MWUserListViewController.h"
#import "UIImage+MWKit.h"

#import "BlockAlertView.h"
#import "BlockTextPromptAlertView.h"

// TODO: Move this to its own file. This isn't kosher.
@implementation ChatMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.message = @"";
        self.userID = @"";
        self.type = MWChatMessage;
    }
    
    return self;
}

@end

@interface MWChatViewController ()

// IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarConstraint;

// Connection information.
@property (copy, nonatomic) NSDictionary *bookmark;
@property (strong, nonatomic) NSMutableArray *chatMessages;
@property (copy, nonatomic) NSString *serverTopic;

@property (strong, nonatomic) MBProgressHUD *progressHUD;

@end

@implementation MWChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 70.0;
}

- (void)loadConnectionSettings {
    // TODO: Need to update all this stuff. Do we still have observers for NSDefaults?
    //       We need to use MWDataStore delegates instead?
    
    // NSUserDefaultsDidChangeNotification doesn't let us know what changed so we tell the server
    // about anything that could have possibly updated.
    
    NSString *nick = self.bookmark[kMWUserNick];
    if ([nick isEqualToString:@""]) {
        nick = [MWDataStore optionForKey:kMWUserNick];
    }
    
    NSString *status = self.bookmark[kMWUserStatus];
    if ([status isEqualToString:@""]) {
        status = [MWDataStore optionForKey:kMWUserStatus];
    }
    
    [self.connection setNick:nick];
    [self.connection setStatus:status];
    [self.connection setIcon:nil];
}

#pragma mark - Wired Connection

- (void)loadBookmark:(NSUInteger)indexRow
{
    // Create a progress HUD.
    if (!self.progressHUD) {
        self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        self.progressHUD.color = [UIColor colorWithWhite:0.0f alpha:0.65f];
        self.progressHUD.delegate = self;
        [self.view addSubview:self.progressHUD];
    }
    
    // Initialize the message list.
    self.chatMessages = [NSMutableArray new];
    
    // Connect to the bookmark.
    self.bookmark = [MWDataStore bookmarkAtIndex:indexRow];
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
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    self.progressHUD.animationType = MBProgressHUDAnimationZoom;
    self.progressHUD.labelText = @"Connecting";
    [self.progressHUD show:YES];
    
    // Create a new WiredConnection.
    self.connection = [[WiredConnection alloc] init];
    self.connection.delegate = self;
    [self.connection connectToServer:self.bookmark[kMWServerHost] onPort:[self.bookmark[kMWServerPort] integerValue]];
}

- (void)disconnect
{
    // This will invoke the didDisconnect delegate method.
    [self.connection disconnect];
}


#pragma mark - IBActions

- (IBAction)sendButtonPressed:(id)sender
{
    [self.connection sendChatMessage:self.textField.text toChannel:@"1"];
    self.textField.text = @"";
    
    [TestFlight passCheckpoint:@"Sent Chat Message (Button)"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.connection sendChatMessage:self.textField.text toChannel:@"1"];
    self.textField.text = @"";
    
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
                                                                             defaultText:self.serverTopic];
            
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

#pragma mark - UITableView Helpers

- (void)addMessageToView:(NSString *)message fromID:(NSString *)userID
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = message;
    newMessage.userID = userID;
    newMessage.type = MWChatMessage;

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"h:mm a"];
    newMessage.time = [dateFormatter stringFromDate:[NSDate new]];
    
    [self.chatMessages addObject:newMessage];
    [self.tableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.chatMessages count]-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
}

- (void)addEmoteToView:(NSString *)emote fromID:(NSString *)userID
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = emote;
    newMessage.userID = userID;
    newMessage.type = MWEmoteMessage;

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"h:mm a"];
    newMessage.time = [dateFormatter stringFromDate:[NSDate new]];
    
    [self.chatMessages addObject:newMessage];
    [self.tableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.chatMessages count]-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
}

- (void)addSystemMessageToView:(NSString *)message withDate:(NSDate *)date
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = message;
    newMessage.type = MWStatusMessage;

    // If a date is given, display it. Otherwise, display the current time.
    // TODO: Calculate time difference to decide if we should show date or time.
    if (date) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"MMM d"];
        newMessage.time = [dateFormatter stringFromDate:date];
    } else {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"h:mm a"];
        newMessage.time = [dateFormatter stringFromDate:[NSDate new]];
    }

    [self.chatMessages addObject:newMessage];
    [self.tableView reloadData];

    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.chatMessages count]-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
}

- (void)addSystemMessageToView:(NSString *)message
{
    [self addSystemMessageToView:message withDate:nil];
}

#pragma mark - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.chatMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWChatMessageCell *cell;

    ChatMessage *message = self.chatMessages[(NSUInteger)[indexPath row]];

    switch (message.type) {
        case MWChatMessage: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MWChatMessageCell"];

            NSDictionary *user = [self.connection userList][@"1"][message.userID];

            cell.timestamp.text = message.time;
            cell.nickname.text = user[@"wired.user.nick"];
            cell.message.text = message.message;
            cell.avatar.image = [UIImage imageWithData:user[@"wired.user.icon"]];

            break;
        }

        case MWEmoteMessage: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MWEmoteMessageCell"];

            NSDictionary *user = [self.connection userList][@"1"][message.userID];

            cell.timestamp.text = message.time;
            cell.message.text = [NSString stringWithFormat:@"%@ %@", user[@"wired.user.nick"], message.message];
            cell.avatar.image = [UIImage imageWithData:user[@"wired.user.icon"]];

            break;
        }

        case MWStatusMessage:
            cell = [tableView dequeueReusableCellWithIdentifier:@"MWStatusMessageCell"];
            
            cell.timestamp.text = message.time;
            cell.message.text = message.message;

            break;
    }

    // Resize the user image and make it circular.
//    CGFloat size = 32.0;
//    userImage = [userImage scaleToSize:CGSizeMake(size, size)];
//    userImage = [userImage withCornerRadius:size/2];
//    cell.imageView.image = userImage;

    // Set a border around the user image.
//    UIColor *borderColor = [UIColor colorWithWhite:0.0 alpha:0.525];
//    cell.imageView.layer.borderColor = borderColor.CGColor;
//    cell.imageView.layer.borderWidth = 0.5;
//    cell.imageView.layer.cornerRadius = size/2;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatMessage *message = self.chatMessages[(NSUInteger)[indexPath row]];

    NSDictionary *attributes;
    CGFloat top = 15.0f, bottom = 15.0f;
    CGFloat left = 0.0f, right = 0.0f, nameHeight = 0.0f;

    switch (message.type) {
        case MWChatMessage:
            left = 50.0f;
            right = 10.0f;
            nameHeight = 20.0f;

            attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:14.0f] };
            break;

        case MWEmoteMessage:
            left = 50.0f;
            right = 88.0f;

            attributes = @{ NSFontAttributeName: [UIFont italicSystemFontOfSize:14.0f] };
            break;

        case MWStatusMessage:
            left = 13.0f;
            right = 90.0f;

            attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:12.0f] };
            break;
    }

    CGFloat width = CGRectGetWidth(tableView.bounds);
    CGRect frame = [message.message boundingRectWithSize:CGSizeMake(width - (left + right), CGFLOAT_MAX)
                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                              attributes:attributes
                                                 context:nil];

    // The minimum height is the user image size + the top and bottom padding.
    CGFloat totalHeight = (CGFloat)ceil(CGRectGetHeight(frame)) + top + bottom + nameHeight;
    CGFloat userImage = (message.type == MWStatusMessage) ? 0.0f : 32.0f;
    CGFloat minimumHeight = userImage + top + bottom;
    
    return (totalHeight > minimumHeight) ? totalHeight : minimumHeight;
}

#pragma mark - UITextField Delegates

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.userListView.connection = self.connection;
    [self mm_drawerController].rightDrawerViewController = self.userListView;

    // Register to listen for NSUserDefaults changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadConnectionSettings)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

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
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Disable opening left/right drawers while typing.
    [self mm_drawerController].openDrawerGestureModeMask = MMOpenDrawerGestureModeNone;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Enable opening left/right drawers again.
    [self mm_drawerController].openDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSTimeInterval animDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animCurve = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationOptions animOption = (UIViewAnimationOptions)animCurve << 16;

    CGRect keyboardFrameEnd = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = 0.0;

    if (UIInterfaceOrientationIsPortrait([self interfaceOrientation])) {
        keyboardHeight = CGRectGetHeight(keyboardFrameEnd);
    } else if (UIInterfaceOrientationIsLandscape([self interfaceOrientation])) {
        keyboardHeight = CGRectGetWidth(keyboardFrameEnd);
    }

    [UIView animateWithDuration:animDuration delay:0.0 options:animOption animations:^{
        self.toolbarConstraint.constant = keyboardHeight;
        [self.toolbar updateConstraintsIfNeeded];
        [[self view] layoutIfNeeded];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.chatMessages count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval animDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animCurve = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationOptions animOption = (UIViewAnimationOptions)animCurve;

    [UIView animateWithDuration:animDuration delay:0.0 options:animOption animations:^{
        self.toolbarConstraint.constant = 0.0;
        [self.toolbar updateConstraintsIfNeeded];
        [[self view] layoutIfNeeded];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self.chatMessages count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    } completion:nil];
}


#pragma mark - Wired Connection Delegates

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
    [self navigationItem].title = self.connection.serverInfo[@"wired.info.name"];
    [self navigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cog.png"]
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(openOptionsMenu)];

    self.progressHUD.labelText = @"Logging In";

    [self loadConnectionSettings];
    [self.connection sendLogin:self.bookmark[kMWUserLogin] withPassword:self.bookmark[kMWUserPass]];
}

/*
 * Received information about a user.
 *
 * This method is called when we receive specifically requested information about a user.
 *
 */
- (void)didReceiveUserInfo:(NSDictionary *)info
{
    [self.userListView didReceiveUserInfo:info];
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
    self.progressHUD.labelText = @"Joining Channel";

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
    self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    self.progressHUD.mode = MBProgressHUDModeCustomView;
    self.progressHUD.labelText = @"Login Failed";
    self.progressHUD.detailsLabelText = reason;
}

/*
 * Connection and login was successful.
 *
 * Called on first connection to the Wired server once the user is finally able to perform actions.
 *
 */
- (void)didConnectAndLoginSuccessfully
{
    self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]];
    self.progressHUD.mode = MBProgressHUDModeCustomView;
    self.progressHUD.labelText = @"Connected";
    [self.progressHUD hide:YES afterDelay:0.5];

    NSString *message = [NSString stringWithFormat:@"Connected to %@.",
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
    self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    self.progressHUD.mode = MBProgressHUDModeCustomView;
    self.progressHUD.labelText = @"Connection Failed";
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
    // Clear the user list for continuity.
    [self.userListView setUserList:[NSDictionary new]];

    self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    self.progressHUD.mode = MBProgressHUDModeCustomView;
    self.progressHUD.labelText = @"Disconnected";
    [self.progressHUD show:YES];

    NSString *message = [NSString stringWithFormat:@"Disconnected from %@.",
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
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    self.progressHUD.labelText = @"Reconnecting";
    [self.progressHUD show:YES];

    NSString *message = [NSString stringWithFormat:@"Disconnected from %@.",
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
    NSString *message = [NSString stringWithFormat:@"Reconnecting in %@ seconds.", delay];
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
    NSString *message = [NSString stringWithFormat:@"Disconnected from %@:%@.",
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
    self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]];
    self.progressHUD.mode = MBProgressHUDModeCustomView;
    self.progressHUD.labelText = @"Reconnected";
    [self.progressHUD hide:YES afterDelay:0.5];

    // Report the disconnect to chat.
    NSString *message = [NSString stringWithFormat:@"Reconnected to %@.",
                         self.connection.serverInfo [@"wired.info.name"]];
    [self addSystemMessageToView:message];

    // Reset the server topic.
    self.serverTopic = nil;

    [TestFlight passCheckpoint:@"Reconnected to Server"];
}

/*
 * Received channel topic from server.
 *
 * Occurs on first joining the channel and on each time the topic is changed thereafter.
 * Only the subsequent changes should notify the user that the topic has changed.
 *
 */
- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel onDate:(NSDate *)date
{
    // Don't report empty topics (no topic is set, or the topic was removed).
    if ([topic isEqualToString:@""]) {
        self.serverTopic = topic;
        return;
    }

    // Someone just changed the topic.
    if (self.serverTopic) {
#ifdef DEBUG
        NSLog(@"%@ | <<< %@ changed topic to '%@' >>>", channel, nick, topic);
#endif

        NSString *message = [NSString stringWithFormat:@"%@ changed topic to \"%@\".", nick, topic];
        [self addSystemMessageToView:message];
    }

    // Initial connection.
    else {
#ifdef DEBUG
        NSLog(@"Channel #%@ topic: %@ (set by %@)", channel, topic, nick);
#endif

        NSString *message = [NSString stringWithFormat:@"%@ — %@.", topic, nick];
        [self addSystemMessageToView:message withDate:date];
    }

    self.serverTopic = topic;
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

    NSString *message = [NSString stringWithFormat:@"%@ has joined.", nick];
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

    NSString *message = [NSString stringWithFormat:@"%@ is now known as %@.", oldNick, newNick];
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

    NSString *message = [NSString stringWithFormat:@"%@ has left.", nick];
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

    BOOL iWasKicked = [userID isEqualToString:self.connection.myUserID];

    // Change the wording if we were the one kicked.
    NSString *verb = @"was";
    if (iWasKicked) {
        nick = @"You";
        verb = @"were";
    }

    NSString *message;
    if ([reason isEqualToString:@""]) {
        message = [NSString stringWithFormat:@"%@ %@ kicked by %@.", nick, verb, kicker];
    } else {
        message = [NSString stringWithFormat:@"%@ %@ kicked by %@ (%@).", nick, verb, kicker, reason];
    }

    [self addSystemMessageToView:message];

    if (iWasKicked) {
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
}

@end
