//
//  Mobile_WiredAppDelegate.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic) IBOutlet UIWindow *window;

@property (nonatomic) UIViewController *centerController;
@property (nonatomic) UIViewController *leftController;
@property (nonatomic) UIViewController *rightController;

@end
