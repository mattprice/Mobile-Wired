//
//  PrettyToolbar+Defaults.m
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

#import "PrettyToolbar+Defaults.h"

@implementation PrettyToolbar (Defaults)

- (void) initializeVars 
{
    self.contentMode = UIViewContentModeRedraw;
    self.shadowOpacity = 0.5;
    self.gradientStartColor = [UIColor colorWithRed:0.914 green:0.914 blue:0.914 alpha:1];
    self.gradientEndColor = [UIColor colorWithRed:0.718 green:0.722 blue:0.718 alpha:1];
    self.topLineColor = [UIColor colorWithRed:0.416 green:0.416 blue:0.416 alpha:.5];
    self.bottomLineColor = [UIColor colorWithRed:0.718 green:0.722 blue:0.718 alpha:1];
    self.tintColor = [UIColor colorWithWhite:0.65 alpha:1];
}

@end
