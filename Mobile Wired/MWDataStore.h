//
//  MWDataStore.h
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

#import <Foundation/Foundation.h>

#define kMWServerName           @"ServerName"
#define kMWServerHost           @"ServerHost"
#define kMWServerPort           @"ServerPort"
#define kMWUserLogin            @"UserLogin"
#define kMWUserPass             @"UserPass"
#define kMWUserNick             @"UserNick"
#define kMWUserStatus           @"UserStatus"
#define kMWUserIcon             @"UserIcon"

#define kMWNotifications        @"Notifications"
#define kMWOnMention            @"OnMention"

@interface MWDataStore : NSObject <NSCoding>

+ (void)load;
+ (BOOL)save;

#pragma mark - Bookmarks
+ (void)addBookmark:(NSMutableDictionary *)newBookmark;
+ (void)setBookmark:(NSMutableDictionary *)newBookmark forIndex:(NSUInteger)index;
+ (void)removeBookmarkAtIndex:(NSUInteger)index;
+ (NSDictionary *)bookmarkAtIndex:(NSUInteger)index;
+ (NSMutableArray *)bookmarks;

#pragma mark - Global Settings
+ (id)optionForKey:(NSString *)key;
+ (void)setOption:(id)option forKey:(NSString *)key;

@end
