# Mobile Wired

[![Build Status](https://travis-ci.org/mattprice/Mobile-Wired.svg?branch=master)](https://travis-ci.org/mattprice/Mobile-Wired)

Mobile Wired is an iPhone app for connecting to [Wired](http://www.read-write.fr/wired/) servers. It is currently a major work-in-progress and is not ready for general consumption.

## Download Instructions

Mobile Wired is being developed for iOS 8 using the latest Xcode 6 Developer Preview. We do not currently use Swift, but we may in the future, so I cannot guarantee that this project will work with older Xcode versions.

We use CocoaPods for dependency management. If you do not have it installed you can find instructions on the [CocoaPods website](http://cocoapods.org).

```bash
# Checkout the repository.
git clone https://github.com/mattprice/Mobile-Wired.git && cd Mobile-Wired

# Make a copy of the sample TestFlightTokens file.
cp 'Mobile Wired/TestFlightTokens-Sample.h' 'Mobile Wired/TestFlightTokens.h'

# Install CocoaPod dependencies.
pod install

# Always open the Xcode workspace instead of the project file.
open Mobile\ Wired.xcworkspace
```

## External Libraries

|          Name          |                   Description                   |
| :--------------------- | :---------------------------------------------- |
| [BlockAlerts][]        | UIAlertView and UIActionSheet replacements      |
| [GCDAsyncSocket][]     | Asynchronous socket networking library          |
| [MBProgressHUD][]      | Translucent HUD with an indicator and/or labels |
| [MMDrawerController][] | A lightweight drawer navigation controller      |
| [SSKeychain][]         | Keychain wrapper that works on Mac and iOS      |
| [TBXML][]              | Super-fast, lightweight, easy to use XML parser |
| [TestFlight][]         | Remote crash logging and in-app updates         |

[BlockAlerts]:        https://github.com/gpambrozio/BlockAlertsAnd-ActionSheets
[GCDAsyncSocket]:     https://github.com/robbiehanson/CocoaAsyncSocket
[MBProgressHUD]:      https://github.com/jdg/MBProgressHUD
[MMDrawerController]: https://github.com/mutualmobile/MMDrawerController
[SSKeychain]:         https://github.com/soffes/sskeychain
[TBXML]:              https://github.com/71squared/TBXML
[TestFlight]:         https://testflightapp.com/sdk/

## License (MIT)

Copyright (c) 2011-2014 Matthew Price, http://mattprice.me/

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.