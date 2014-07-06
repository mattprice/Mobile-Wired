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

#import "MWServerListViewController.h"

#import "UIViewController+MMDrawerController.h"
#import "MMDrawerVisualState.h"

@implementation MWDrawerController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Mobile Wired initially displays the Bookmarks view in fullscreen (no center view).
    self.showsShadow = NO;
    self.shouldStretchDrawer = YES;
    self.maximumLeftDrawerWidth = [[UIScreen mainScreen] bounds].size.width;
    self.openDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    self.closeDrawerGestureModeMask = MMCloseDrawerGestureModeNone;
    self.centerHiddenInteractionMode = MMDrawerOpenCenterInteractionModeNone;
    [self setDrawerVisualStateBlock:[MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:2.0f]];

    // Create and set up the view controllers.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kMWLeftDrawer bundle:nil];
    UINavigationController *bookmarksView = [storyboard instantiateViewControllerWithIdentifier:kMWLeftNavigationController];

    // Assign the view controllers to their respective sides.
    [self setLeftDrawerViewController:bookmarksView];
    [self setCenterViewController:[UIViewController new]];
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
