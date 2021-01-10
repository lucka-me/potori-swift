# ![](./Readme/title.png)

[![License](https://img.shields.io/github/license/lucka-me/potori-swift)](./LICENSE "License")  
[![Telegram Channel](https://img.shields.io/badge/telegram-channel-37aee2?logo=telegram)](https://t.me/potori "Telegram Channel")

## Description

An app to visualize Ingress nominations from Gmail inbox, available for macOS and iOS.

This is the Swift implementation of [the web app](https://github.com/lucka-me/potori).

## Requirements
- Xcode 12+
- macOS 11+
- iOS 13+

## Transfer from the Web App
In this project, we implemented a new data structure without fully backward compatiable (which will also be implemented into the web app in the future). It will be fine to transfer data from the web app to this app with exporting & importing JSON file or sync with Google Drive, but it's not recommended to transfer backwards.

For Google Drive sync, this app will download `nominations.json` if it exists, or `potori.json` if not, and upload data to `nominations.json`, it will not update `potori.json` used by the current web app.

## Task List
We hope to implement all features of the web app, and bring more feature with platform support.

- [x] Core Features
  - [x] Data structure for nominations
  - [x] Status data manager
  - [x] Login Google account
  - [x] Mail processor
- [x] Data Manager
  - [x] Store data with Core Data
  - [x] Export / Import nominations to / from JSON file
  - [x] Sync with Google Drive
- [ ] Brainstorming
  - [ ] Data structure
  - [ ] Store data with Core Data
  - [ ] Firebase query
- [ ] User Interface with SwiftUI 2.0
  - [x] Navigation for all platform
  - [x] Nomination List
  - [x] Nomination Details
  - [ ] Nomination Editor
  - [ ] Filter
  - [ ] Re-order
  - [ ] Stats Panel
    - [x] Basic stats
    - [ ] Charts
  - [x] Map Panel
  - [x] Preference View
- [ ] Platform Features
  - [ ] Background update & notification
  - [ ] Wedget
- [ ] Project
  - [ ] CI workflow
- [ ] Requires Apple Developer Program
  - [ ] Sync with iCloud

## License
The source code are [licensed under MIT](./LICENSE).

Please notice that the Client ID included in the source code is owned by [Lucka](https://github.com/lucka-me) and **ONLY** for public useage in the app.

This project is NOT affiliated to Ingress or Niantic.
