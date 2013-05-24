# Mobile Wired

Mobile Wired is an iPhone app for connecting to [Wired](http://www.read-write.fr/wired/) servers. It is currently a major work-in-progress and is not ready for general consumption.

[![Build Status](https://travis-ci.org/mattprice/Mobile-Wired.png)](https://travis-ci.org/mattprice/Mobile-Wired)

## Download Instructions
```bash
# Checkout the repository and download all the required submodules:
git clone https://github.com/mattprice/Mobile-Wired.git && cd Mobile-Wired

# Make a copy of the sample TestFlightTokens file.
cp 'Mobile Wired/TestFlightTokens-Sample.h' 'Mobile Wired/TestFlightTokens.h'

# Compile using Xcode or the command line
xcodebuild
```

## External Resources

* [BlockAlerts][]          — UIAlertView and UIActionSheet replacements inspired by TweetBot.
* [GCDAsyncSocket][]       — Asynchronous socket networking library.
* [IIViewDeckController][] — Sliding views as found in the Path 2.0 or Facebook iOS apps.
* [MBProgressHUD][]        — Class for displaying a translucent HUD with an indicator and/or labels.
* [PrettyKit][]            — Widgets and UIKit subclasses that gives you deeper UIKit customization.
* [TBXML][]                — Super-fast, lightweight, easy to use XML parser.
* [TestFlight SDK][]       — Remote crash logging and in-app updates for beta testers.

[BlockAlerts]:             https://github.com/gpambrozio/BlockAlertsAnd-ActionSheets
[GCDAsyncSocket]:          https://github.com/robbiehanson/CocoaAsyncSocket
[IIViewDeckController]:    https://github.com/Inferis/ViewDeck
[MBProgressHUD]:           https://github.com/jdg/MBProgressHUD
[PrettyKit]:               https://github.com/vicpenap/PrettyKit
[TBXML]:                   https://github.com/71squared/TBXML
[TestFlight SDK]:          https://testflightapp.com/sdk/

## License (MIT)

Copyright (c) 2012 Matthew Price, http://mattprice.me/ <br>
Copyright (c) 2012 Ember Code, http://embercode.com/

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.