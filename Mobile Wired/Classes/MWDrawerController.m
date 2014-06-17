//
//  MWDrawerController.m
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

#import "MWDrawerController.h"

#import "MWBookmarksViewController.h"
#import "MWBookmarkSettingsController.h"

@implementation MWDrawerController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // MMDrawerController Settings.
    // Mobile Wired initially displays the Bookmarks view in fullscreen (no center view) so most
    // of these settings get changed when the user selects something for the first time.
    self.showsShadow = NO;
    self.shouldStretchDrawer = NO;
    self.maximumLeftDrawerWidth = [[UIScreen mainScreen] bounds].size.width;
    self.centerHiddenInteractionMode = MMDrawerOpenCenterInteractionModeNone;
    self.openDrawerGestureModeMask = MMOpenDrawerGestureModeNone;
    self.closeDrawerGestureModeMask = MMCloseDrawerGestureModeNone;

    // Create and set up the view controllers.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kMWMainStoryboard bundle:nil];
    UINavigationController *bookmarksView = [storyboard instantiateViewControllerWithIdentifier:kMWLeftNavigationController];
    MWBookmarkSettingsController *bookmarkSettings = [storyboard instantiateViewControllerWithIdentifier:kMWBookmarkSettingsController];

    // Assign the view controllers to their respective sides.
    [self setLeftDrawerViewController:bookmarksView];
    [self setCenterViewController:bookmarkSettings];
    [self openDrawerSide:MMDrawerSideLeft animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Layout

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return nil;
}

#pragma mark - Autorotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Status Bar Appearance

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}


@end