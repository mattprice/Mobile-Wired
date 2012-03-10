//
//  ChatViewController.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "ChatViewController.h"
#import "IIViewDeckController.h"
#import "NSString+Hashes.h"
#import "UserListViewController.h"

@interface ChatViewController (private)
    - (void)animateKeyboardReturnToOriginalPosition;
    - (void)animateKeyboardOffscreen;
@end

@implementation ChatViewController

@synthesize connection = _connection;
@synthesize navigationBar = _navigationBar;
@synthesize userListView, badgeCount;

#pragma mark -
#pragma mark Wired Connection Methods

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create the navigation bar
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    self.navigationBar.items = [NSArray arrayWithObject:navItem];
    
    // Customize the bar title and buttons
    self.navigationBar.topItem.title = @"Cunning Giraffe";
    self.navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Users"]
                                                                                     style:UIBarButtonItemStyleBordered
                                                                                    target:self.viewDeckController
                                                                                    action:@selector(toggleRightView)];
    
    // Create a Progress HUD
    if (!progressHUD) {
        progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        progressHUD.delegate = self;
        [self.view addSubview:progressHUD];
    }
    
    // Update the Progress HUD
    progressHUD.mode = MBProgressHUDModeIndeterminate;
    progressHUD.animationType = MBProgressHUDAnimationZoom;
    progressHUD.labelText = @"Connecting";
    [progressHUD show:YES];
    
    // Create a new WiredConnection.
    self.connection = [[WiredConnection alloc] init];
    self.connection.delegate = self;
    [self.connection connectToServer:@"chat.embercode.com" onPort:2359];
}

- (IBAction)sendButtonPressed:(id)sender
{
    // Send the message
    [self.connection sendChatMessage:chatTextField.text toChannel:@"1"];
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    chatTextField.text = @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Send the message
    [self.connection sendChatMessage:chatTextField.text toChannel:@"1"];
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
    chatTextField.text = @"";
    
    return YES;
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
    // Set up the DefaultUserIcon if the user hasn't selected one of their one.
    progressHUD.labelText = @"Logging In";
    [self.connection setNick:@"Melman"];
    [self.connection setIcon:nil];
    [self.connection setStatus:[NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]]];
    [self.connection sendLogin:@"guest" withPassword:[@"" SHA1Value]];
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
//    [self.connection sendChatMessage:@"Test..." toChannel:@"1"];

//    [self.connection sendChatEmote:@"is having fun!" toChannel:@"1"];
//    [self.connection sendChatMessage:@"/me is testing slash commands!" toChannel:@"1"];

//    [self.connection sendChatMessage:@"/afk" toChannel:@"1"];
//    [self.connection setIdle];
//    [self.connection disconnect];

//    [self.connection sendBroadcast:@"Broadcast"];
}

- (void)userStatusDidChange:(NSString *)newStatus withNick:(NSString *)nick withID:(NSString *)userID
{

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
    if (serverTopic == nil) {
        NSLog(@"Channel #%@ topic: %@ (set by %@)",channel,topic,nick);
    }

    // Subsequent topic changes, so we should notify the user.
    else {
        NSLog(@"%@ | <<< %@ changed topic to '%@' >>>",channel,nick,topic);
    }

    [serverTopic setText:topic];
}

- (void)didReceiveChatMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
//    NSLog(@"%@ | %@ (%@) : %@",channel,nick,userID,message);
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"%@: %@\n", nick, message];
    chatTextView.text = chatText;
    
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

/*
 * Received a private message from some user.
 *
 * Message could be from anyone, including yourself.
 *
 */
- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
//    NSLog(@"%@ (%@) : %@",nick,userID,message);
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",nick,message];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    self.badgeCount++;
    localNotification.applicationIconBadgeNumber = self.badgeCount;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

/*
 * Received a broadcast from someone.
 *
 * Message could be from anyone, including yourself.
 *
 */
- (void)didReceiveBroadcast:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
//    NSLog(@"%@ (%@) : %@",nick,userID,message);
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",nick,message];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    self.badgeCount++;
    localNotification.applicationIconBadgeNumber = self.badgeCount;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
//    NSLog(@"%@ | %@ (%@) %@",channel,nick,userID,message);
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"*** %@ %@\n",nick,message];
    chatTextView.text = chatText;
    
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

- (void)userJoined:(NSString *)nick withID:(NSString *)userID
{
//    NSLog(@"<<< %@ has joined >>>",nick);
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< %@ has joined >>>\n",nick];
    chatTextView.text = chatText;
    
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

- (void)userChangedNick:(NSString *)oldNick toNick:(NSString *)newNick
{
//    NSLog(@"<<< %@ is now known as %@ >>>",oldNick,newNick);
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< %@ is now known as %@ >>>\n",oldNick,newNick];
    chatTextView.text = chatText;
    
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];    
}

- (void)userLeft:(NSString *)nick withID:(NSString *)userID
{
//    NSLog(@"<<< %@ has left >>>",nick);
    
    NSMutableString *chatText = [chatTextView.text mutableCopy];
    [chatText appendFormat:@"<<< %@ has left >>>\n",nick];
    chatTextView.text = chatText;
    
    [chatTextView scrollRangeToVisible:NSMakeRange([chatTextView.text length], 0)];
}

- (void)didFailLoginWithReason:(NSString *)reason
{
    // Update the Progress HUD
	progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Login Failed";
    progressHUD.detailsLabelText = reason;
//    [progressHUD hide:YES afterDelay:10];
}

- (void)didFailConnectionWithReason:(NSError *)error
{
    // Update the Progress HUD
	progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Connection Failed";
}

/*
 * Received information about a user.
 *
 * This method is called when we receive specifically requested information about a user.
 *
 */
- (void)didReceiveUserInfo:(NSDictionary *)info
{

}

- (void)setUserList:(NSDictionary *)userList
{
    [userListView setUserList:userList];
    [userListView.tableView setNeedsDisplay];
    
    // Update the Progress HUD
	progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Connected";
    [progressHUD hide:YES afterDelay:2];
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
#pragma mark Sliding Keyboard Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Be sure we know which keyboard is selected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textfieldWasSelected:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    
    // Register an event for when a keyboard pops up
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)textfieldWasSelected:(NSNotification *)notification
{
    chatTextField = notification.object;
    
    // Move the textField out of the keyboard's way.
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         accessoryView.frame = CGRectMake(0.0, 200.0, accessoryView.frame.size.width, accessoryView.frame.size.height);
                         chatTextView.frame = CGRectMake(chatTextView.frame.origin.x, chatTextView.frame.origin.y, chatTextView.frame.size.width, 155.0);
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
    
    // Create UIGestureRecognizer for sliding the keyboard down.
    // This gets removed once the keyboard disappears.
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if(keyboard) return;
    
    // We can't access the UIKeyboard through the SDK we have to use a UIView.
    // See discussion http://www.iphonedevsdk.com/forum/iphone-sdk-development/6573-howto-customize-uikeyboard.html
    
    UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    for(int i = 0; i < [tempWindow.subviews count]; i++) {
        UIView *possibleKeyboard = [tempWindow.subviews objectAtIndex:i];
        if([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES){
            keyboard = possibleKeyboard;
            return;
        }
    }
}

- (void)adjustAccessoryView
{
    // Pan the accessoryView up/down.
    accessoryView.frame = CGRectMake(0.0, keyboard.frame.origin.y - 64, accessoryView.frame.size.width, accessoryView.frame.size.height);
    
    // Lengthen the chat view.
    chatTextView.frame = CGRectMake(chatTextView.frame.origin.x, chatTextView.frame.origin.y, chatTextView.frame.size.width, accessoryView.frame.origin.y - 45);
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
                        options:UIViewAnimationCurveEaseInOut
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
                         
                         // Remove the UIGestureRecognizer so that you can swipe left/right again.
                         [self.view removeGestureRecognizer:panRecognizer];
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
