# ![](./Readme/title.png)

[![Lines of code](https://img.shields.io/tokei/lines/github/lucka-me/potori-swift)](# "Repository")
[![License](https://img.shields.io/github/license/lucka-me/potori-swift)](./LICENSE "License")  
[![Telegram Channel](https://img.shields.io/badge/telegram-channel-37aee2?logo=telegram)](https://t.me/potori "Telegram Channel")

## Description

An app to visualize Ingress nominations from Gmail inbox, available for macOS and iOS.

This is the Swift implementation of [the web app](https://github.com/lucka-me/potori).

## Requirements
- Xcode 12+
- macOS 11+
- iOS 14+

## Build & Run

1. Clone or download the repository
2. Open `Potori.xcodeproj`
3. Choose your target and connect your device if necessary
4. Hit `⌘ R`

## Transfer from the Web App
In this project, we implemented a new data structure without fully backward compatiable (which will also be implemented into the web app in the future). It will be fine to transfer data from the web app to this app with exporting & importing JSON file or sync with Google Drive, but it's not recommended to transfer backwards.

For Google Drive sync, this app will download and upload `nominations.json`, it will not update `potori.json` used by the current web app.

## Task List
We hope to implement all features of the web app, and bring more with platform support.

[Track progress for the initial release](https://github.com/lucka-me/potori-swift/projects/1)

## License
The source code are [licensed under MIT](./LICENSE).

Please notice that the Client ID included in the source code is owned by [Lucka](https://github.com/lucka-me) and **ONLY** for public useage in the app.

This project is NOT affiliated to Ingress or Niantic.
