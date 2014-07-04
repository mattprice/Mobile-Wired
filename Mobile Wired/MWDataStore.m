//
//  MWDataStore.m
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

#import "MWDataStore.h"

#import "SSKeychain.h"

@implementation MWDataStore

static MWDataStore *sharedInstance;

static NSUInteger version;
static NSMutableDictionary *settings;
static NSMutableArray *bookmarks;

+ (void)load
{
    sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithFile:[MWDataStore dataPath]];
}

+ (BOOL)save
{
    return [NSKeyedArchiver archiveRootObject:sharedInstance toFile:[MWDataStore dataPath]];
}

+ (NSString *)dataPath
{
    static NSString *dataPath = @"";

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        dataPath = [documentDirectory stringByAppendingPathComponent:@"data.plist"];
    });

    return dataPath;
}

#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)coder
{
    version = (coder) ? [coder decodeIntegerForKey:@"version"] : 0;

    // New User
    if (version == 0) {
        NSLog(@"Creating MWDataStore for the first time.");
        version = 1;

        settings = [NSMutableDictionary new];
        settings[kMWUserNick] = @"Mobile Wired User";
        settings[kMWUserStatus] = [NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]];

        bookmarks = [NSMutableArray new];

        return self;
    }

    // Future upgrade routines...
//    if (version < 2) {
//        NSLog(@"Updating MWDataStore from version %ld to 2.", (long)version);
//        version = 2;
//        return self;
//    }

    // Existing User
    settings = [coder decodeObjectForKey:@"settings"];
    bookmarks = [coder decodeObjectForKey:@"bookmarks"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:version forKey:@"version"];
    [coder encodeObject:settings forKey:@"settings"];
    [coder encodeObject:bookmarks forKey:@"bookmarks"];
}

#pragma mark - Bookmarks

+ (NSString *)keychainAccountForBookmark:(NSDictionary *)bookmark
{
    NSString *user = bookmark[kMWUserLogin];
    NSString *host = bookmark[kMWServerHost];
    NSString *port = bookmark[kMWServerPort];

    return [NSString stringWithFormat:@"%@@%@:%@", user, host, port];
}

+ (void)deleteKeychainAccount:(NSString *)account
{
    BOOL success = [SSKeychain deletePasswordForService:[[NSBundle mainBundle] bundleIdentifier] account:account];
    if (!success) {
        NSLog(@"Deleting Keychain account '%@' failed.", account);
    }
}

+ (void)addBookmark:(NSMutableDictionary *)bookmark
{
    // Add the password to the Keychain.
    if (bookmark[kMWUserLogin] && bookmark[kMWUserPass]) {
        NSLog(@"Adding password to Keychain.");

        [SSKeychain setPassword:bookmark[kMWUserPass]
                     forService:[[NSBundle mainBundle] bundleIdentifier]
                        account:[self keychainAccountForBookmark:bookmark]];
    }

    // Remove the password from the bookmark.
    [bookmark removeObjectForKey:kMWUserPass];

    // Store the resulting bookmark.
    [bookmarks addObject:(NSDictionary *)bookmark];
    [self save];

    [TestFlight passCheckpoint:@"Added Bookmark"];
}

+ (void)setBookmark:(NSMutableDictionary *)bookmark forIndex:(NSUInteger)index
{
    // Delete the old password from the Keychain.
    NSString *account = [self keychainAccountForBookmark:bookmarks[index]];
    [self deleteKeychainAccount:account];

    // Add the new password to the Keychain.
    if (bookmark[kMWUserLogin] && bookmark[kMWUserPass]) {
        NSLog(@"Adding password to Keychain.");
        [SSKeychain setPassword:bookmark[kMWUserPass]
                     forService:[[NSBundle mainBundle] bundleIdentifier]
                        account:[self keychainAccountForBookmark:bookmark]];
    }

    // Remove the password from the bookmark.
    [bookmark removeObjectForKey:kMWUserPass];

    // Store the resulting bookmark.
    [bookmarks setObject:(NSDictionary *)bookmark atIndexedSubscript:index];
    [self save];

    [TestFlight passCheckpoint:@"Edited Bookmark"];
}

+ (void)removeBookmarkAtIndex:(NSUInteger)index
{
    // Delete account from the Keychain.
    NSString *account = [self keychainAccountForBookmark:bookmarks[index]];
    [self deleteKeychainAccount:account];

    [bookmarks removeObjectAtIndex:index];
    [self save];
}

+ (NSDictionary *)bookmarkAtIndex:(NSUInteger)index
{
    NSMutableDictionary *bookmark = [bookmarks[index] mutableCopy];

    // Fetch the password from the Keychain.
    NSString *password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier]
                                                account:[self keychainAccountForBookmark:bookmark]];
    if (password) {
        bookmark[kMWUserPass] = password;
    }

    return bookmark;
}

+ (NSMutableArray *)bookmarks
{
    NSMutableArray *_bookmarks = [NSMutableArray new];
    for (int i = 0; i < [bookmarks count]; i++) {
        _bookmarks[i] = [self bookmarkAtIndex:i];
    }

    return _bookmarks;
}

#pragma mark - Global Settings

+ (id)optionForKey:(NSString *)key
{
    return settings[key];
}

+ (void)setOption:(id)option forKey:(NSString *)key
{
    settings[key] = option;
}

@end
