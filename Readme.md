## About

Mobile Wired is an iPhone app for connecting to [Wired](http://www.read-write.fr/wired/) servers. It is currently a major work-in-progress and is not ready for general consumption.

## Download Instructions

1. Checkout the repository and download all the required submodules:
    * `$ git clone --recursive https://github.com/mattprice/Mobile-Wired.git`
2. Make a copy of the sample TestFlightTokens file:
    * `$ cd Mobile-Wired/Mobile\ Wired/ && cp TestFlightTokens-Sample.h TestFlightTokens.h`
3. Compile using Xcode or the command line:
    * `$ cd .. && xcodebuild`

## Changelog

| **Version** | **Build** | **Changes** |
| :---------: | :-------: | :---------- |
|    0.8.1    |    174    | <ul><li>Fixed a bug that caused passwords to occasionally be forgotten.</li><li>Added the ability to disconnect from a server.</li><li>Added prettier, custom alerts.</li></ul> |
|    0.8      |    168    | <ul><li>Roughly a half a billion changes.</li><li>The first fully functioning public beta of Mobile Wired.</li></ul> |
|    0.6      |    70     | <ul><li>Mobile Wired UI was rewritten from the ground up to support a new interface inspired by Path 2.0 and Facebook.</li></ul> |
|    0.5.1    |           | <ul><li>Fixed crashing on pre-iOS 5 devices due to a bug in Beta 5 of the iOS 5 SDK.</li><li>New application icon and loading screen.</li></ul> |
|    0.5      |           | <ul><li>Initial beta release.</li></ul> |

## External Resources

* [BlockAlerts][] — Beautifully done UIAlertView and UIActionSheet replacements inspired by TweetBot.
* [GCDAsyncSocket][] — Asynchronous socket networking library for Mac and iOS.
* [IIViewDeckController][] — An implementation of the sliding views found in the Path 2.0 or Facebook iOS apps.
* [MBProgressHUD][] — iOS class for displaying a translucent HUD with an indicator and/or labels.
* [PrettyKit][] — A small set of widgets and UIKit subclasses that gives you deeper UIKit customization.
* [TBXML][] — Super-fast, lightweight, easy to use XML parser for the Mac and iOS.
* [TestFlight SDK][] — Remote crash logging and in-app updates for beta testers.

[BlockAlerts]: https://github.com/Lyc0s/BlockAlertsAnd-ActionSheets
[GCDAsyncSocket]: https://github.com/robbiehanson/CocoaAsyncSocket
[IIViewDeckController]: https://github.com/Inferis/ViewDeck*
[MBProgressHUD]: https://github.com/jdg/MBProgressHUD
[PrettyKit]: https://github.com/vicpenap/PrettyKit
[TBXML]: https://github.com/71squared/TBXML
[TestFlight SDK]: https://testflightapp.com/sdk/

## MIT License (MIT)

Copyright (c) 2012 Matthew Price, http://mattprice.me/ <br>
Copyright (c) 2012 Ember Code, http://embercode.com/

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.