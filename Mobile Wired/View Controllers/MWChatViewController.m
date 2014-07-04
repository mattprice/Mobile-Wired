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
#import "UserInfoViewController.h"
#import "UserListViewController.h"
#import "UIImage+MWKit.h"

#import "BlockAlertView.h"
#import "BlockTextPromptAlertView.h"

// TODO: Move this to its own file. This isn't kosher.
@implementation ChatMessage

- (id)init
{
    if ((self = [super init])) {
        self.message = @"";
        self.userID = @"";
        self.type = MWChatMessage;
    }
    
    return self;
}

@end

@interface MWChatViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarConstraint;

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
    
    NSString *nick = bookmark[kMWUserNick];
    if ([nick isEqualToString:@""]) {
        nick = [MWDataStore optionForKey:kMWUserNick];
    }
    
    NSString *status = bookmark[kMWUserStatus];
    if ([status isEqualToString:@""]) {
        status = [MWDataStore optionForKey:kMWUserStatus];
    }
    
    [self.connection setNick:nick];
    [self.connection setStatus:status];
    [self.connection setIcon:nil];
}

#pragma mark - Drawer Controller

//- (IIViewDeckController *)userListViewController
//{
//    return (IIViewDeckController *)self.viewDeckController.rightController;
//}
//
//- (void)viewDeckController:(IIViewDeckController *)viewDeckController didShowCenterViewFromSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated
//{
//    // Close the UserInfoView whenever the User List is closed.
//    if ( viewDeckSide == IIViewDeckRightSide ) {
//        [self.userListViewController closeRightView];
//    }
//}

#pragma mark - Wired Connection

- (void)loadBookmark:(NSUInteger)indexRow
{
    // Create a progress HUD.
    if (!progressHUD) {
        progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        progressHUD.delegate = self;
        [self.view addSubview:progressHUD];
    }
    
    // Initialize the message list.
    chatMessages = [NSMutableArray new];
    
    // Connect to the bookmark.
    bookmark = [MWDataStore bookmarkAtIndex:indexRow];
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
    [self.connection connectToServer:bookmark[kMWServerHost] onPort:[bookmark[kMWServerPort] integerValue]];
    self.userListView.connection = self.connection;
}

- (void)disconnect
{
    // Disconnect from the server.
    // This will invoke the didDisconnect delegate method.
    [self.connection disconnect];
}


#pragma mark - UI Actions

- (IBAction)sendButtonPressed:(id)sender
{
    // Send the message.
    [self.connection sendChatMessage:self.textField.text toChannel:@"1"];
    self.textField.text = @"";
    
    [TestFlight passCheckpoint:@"Sent Chat Message (Button)"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Send the message.
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
    
    [chatMessages addObject:newMessage];
    [self.tableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[chatMessages count]-1 inSection:0];
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
    
    [chatMessages addObject:newMessage];
    [self.tableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[chatMessages count]-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
}

- (void)addSystemMessageToView:(NSString *)message
{
    ChatMessage *newMessage = [ChatMessage new];
    newMessage.message = message;
    newMessage.type = MWStatusMessage;

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"h:mm a"];
    newMessage.time = [dateFormatter stringFromDate:[NSDate new]];
    
    [chatMessages addObject:newMessage];
    [self.tableView reloadData];
    
    // Scroll to the new message.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[chatMessages count]-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
}

#pragma mark - UITableView Data Source

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
    return (NSInteger)[chatMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWChatMessageCell *cell;

    NSUInteger row = (NSUInteger)[indexPath row];
    ChatMessage *message = chatMessages[row];

    switch (message.type) {
        case MWChatMessage:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MWChatMessageCell"];

            NSDictionary *user = [self.connection userList][@"1"][message.userID];

            cell.timestamp.text = message.time;
            cell.nickname.text = user[@"wired.user.nick"];
            cell.message.text = message.message;
            cell.avatar.image = [UIImage imageWithData:user[@"wired.user.icon"]];

            break;
        }

        case MWEmoteMessage:
        {
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

        default:
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
    NSUInteger row = (NSUInteger)[indexPath row];
    ChatMessage *message = chatMessages[row];

    NSDictionary *attributes;
    CGFloat top = 15.0, bottom = 15.0;
    CGFloat left = 0.0, right = 0.0, nameHeight = 0.0;

    switch (message.type) {
        case MWChatMessage:
            left = 50.0;
            right = 10.0;
            nameHeight = 20.0;

            attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:14.0] };
            break;

        case MWEmoteMessage:
            left = 50.0;
            right = 88.0;

            attributes = @{ NSFontAttributeName: [UIFont italicSystemFontOfSize:14.0] };
            break;

        case MWStatusMessage:
            left = 13.0;
            right = 90.0;

            attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:12.0] };
            break;
    }

    CGFloat width = CGRectGetWidth(tableView.bounds);
    CGRect frame = [message.message boundingRectWithSize:CGSizeMake(width - (left + right), CGFLOAT_MAX)
                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                              attributes:attributes
                                                 context:nil];

    // The minimum height is the user image size + the top and bottom padding.
    CGFloat totalHeight = ceil(CGRectGetHeight(frame)) + top + bottom + nameHeight;
    CGFloat userImage = (message.type == MWStatusMessage) ? 0.0 : 32.0;
    CGFloat minimumHeight = userImage + top + bottom;
    
    return (totalHeight > minimumHeight) ? totalHeight : minimumHeight;
}

#pragma mark - UITextField Delegates

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Register to listen for NSUserDefaults changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadConnectionSettings)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    // Enable sliding to see the user list.
//    IIViewDeckController *rightView = (IIViewDeckController *)self.viewDeckController.rightController;
//    rightView.centerController = self.userListView;
    
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
        self.tableView.contentInset = UIEdgeInsetsMake([self.tableView contentInset].top,
                                                       [self.tableView contentInset].left,
                                                       keyboardHeight + [self.toolbar bounds].size.height,
                                                       [self.tableView contentInset].right);
        self.tableView.scrollIndicatorInsets = [self.tableView contentInset];
        self.toolbarConstraint.constant = keyboardHeight;

        // Scroll to bottom of chatTableView.
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self->chatMessages count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];

        [self.toolbar updateConstraintsIfNeeded];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval animDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animCurve = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationOptions animOption = (UIViewAnimationOptions)animCurve;

    [UIView animateWithDuration:animDuration delay:0.0 options:animOption animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake([self.tableView contentInset].top,
                                                       [self.tableView contentInset].left,
                                                       [self.toolbar bounds].size.height,
                                                       [self.tableView contentInset].right);
        self.tableView.scrollIndicatorInsets = [self.tableView contentInset];
        self.toolbarConstraint.constant = 0.0;

        // Scroll to bottom of chatTableView.
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)[self->chatMessages count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];

        [self.toolbar updateConstraintsIfNeeded];
        [[self view] layoutIfNeeded];
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
    // Customize the bar title and buttons.
    [self navigationItem].title = self.connection.serverInfo[@"wired.info.name"];
    [self navigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Cog.png"]
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(openOptionsMenu)];

    // Update the progress HUD.
    progressHUD.labelText = @"Logging In";

    [self loadConnectionSettings];
    [self.connection sendLogin:bookmark[kMWUserLogin] withPassword:bookmark[kMWUserPass]];
}

/*
 * Received information about a user.
 *
 * This method is called when we receive specifically requested information about a user.
 *
 */
- (void)didReceiveUserInfo:(NSDictionary *)info
{
    //    UserInfoViewController *infoController = [[UserInfoViewController alloc] initWithNibName:@"UserInfoView"
    //                                                                                      bundle:nil
    //                                                                                    userInfo:info];

    // Nested ViewDeckControllers!
    // This controller already exists (AppDelegate.m) but we need to set up its right-most view.
    //    IIViewDeckController *rightView = (IIViewDeckController *)self.viewDeckController.rightController;
    //    rightView.rightController = infoController;
    //    rightView.rightSize = 66;
    //    [rightView openRightViewAnimated:YES];
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

@end
