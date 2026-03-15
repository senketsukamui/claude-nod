# ClaudeNod

[![macOS](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white)](https://www.swift.org/)
[![Status](https://img.shields.io/badge/status-fun%20demo-1f8b4c)](https://github.com/senketsukamui/claude-nod)
[![License](https://img.shields.io/badge/license-MIT-blue)](#license)

Accept or reject Claude Code prompts by nodding or shaking your head while wearing AirPods.

ClaudeNod is a tiny native macOS menu bar utility built for fun. It reads AirPods head motion, detects simple gestures, and can now talk to a tiny local Claude wrapper so setup is much less fragile.

## Demo Idea

- Nod your head to accept
- Shake your head to reject
- Keep your hands on the keyboard
- Look mildly futuristic in the process

## What It Does Today

- Streams motion from supported AirPods using Apple's headphone motion APIs
- Detects `nod` and `shake` gestures with lightweight heuristics
- Lives in the macOS menu bar
- Sends configurable accept and reject payloads like `y + Enter` or `n + Enter`
- Supports a local `bin/claudenod` wrapper that watches real Claude output and sends responses back without screen scraping
- Falls back to frontmost-app detection for Terminal, iTerm, Ghostty, Warp, and Claude Desktop
- Works as a guarded one-shot action so accidental head movement is less risky

## Easiest Setup

The smoothest path is:

1. Run the macOS app from Xcode
2. Launch Claude through the wrapper:

```bash
chmod +x bin/claudenod
bin/claudenod
```

3. Use Claude normally
4. When Claude shows a confirmation, ClaudeNod auto-arms
5. Nod to accept or shake to reject

In wrapper mode, ClaudeNod reads Claude output directly and sends the response back to the same session. That means no Accessibility or Screen Recording permission is required for the main happy path.

## Why It Is "Armed" In v1

The first real product risk is accidental approval.

So v1 uses an intentionally safe flow:

1. Open a Claude Code confirmation
2. Let ClaudeNod auto-arm when it detects the prompt, or arm it manually
3. Nod to accept or shake to reject

That gives us a working utility now while we build smarter prompt detection next.

## Current Scope

Supported hosts right now:

- Terminal
- iTerm
- Ghostty
- Warp
- Claude desktop, if the confirmation field is focused
- ClaudeNod wrapper

Current limitations:

- Wrapper prompt detection still uses text heuristics and may miss unusual confirmation wording
- Gesture tuning is early and may need calibration per person
- Accessibility permission is only required for fallback frontmost-app control
- This is not App Store packaged yet

## Screenshots

Add a menu bar screenshot or short GIF here once you have one. A tiny looping demo will make this repo much more shareable.

## Tech Stack

- `Swift`
- `SwiftUI`
- `AppKit`
- `Core Motion`
- macOS `Accessibility` APIs

## Project Structure

```text
Sources/
  ClaudeNodApp.swift           App entry point
  AppState.swift               Shared app state and action flow
  HeadphoneMotionService.swift AirPods motion streaming
  GestureDetector.swift        Nod/shake detection
  ClaudeCodeController.swift   Keyboard input dispatch
  MenuBarView.swift            Menu bar UI
  SettingsView.swift           Small configuration screen
```

## Getting Started

### Requirements

- macOS 14 or newer
- Xcode 16+ or a recent Swift toolchain
- Supported AirPods with motion data
- Optional Accessibility permission for fallback host control

### Run In Xcode

1. Clone the repo
2. Open [ClaudeNod.xcodeproj](./ClaudeNod.xcodeproj) in Xcode
3. Select the `ClaudeNod` scheme
4. Run the app
5. Look for the `ClaudeNod` icon in the menu bar

### Regenerate The Xcode Project

If you add or remove source files, regenerate the checked-in project with:

```bash
ruby scripts/generate_xcodeproj.rb
```

### Build From Terminal

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project ClaudeNod.xcodeproj -scheme ClaudeNod -configuration Debug build
```

## How To Test

### 1. Verify AirPods Motion

- Put on supported AirPods
- Open the ClaudeNod menu bar item
- Move your head and watch `Pitch / Yaw / Roll`

If those numbers change, the motion pipeline works.

### 2. Dry Run The Action Path

- Enable `Arm next confirmation`
- Click `Test Accept` or `Test Reject`

This tests the same approval pipeline without needing a real gesture.

### 3. Test With A Text Field

- Focus a text field, Notes, or a terminal prompt
- Arm ClaudeNod
- Nod and check whether it types the accept payload
- Arm again and shake to test reject

### 4. Test With Claude Code

Recommended:

- Start Claude with `bin/claudenod`
- Open a prompt that expects confirmation
- Watch ClaudeNod switch to `Connected to ClaudeNod wrapper`
- Nod to accept or shake to reject

Fallback mode:

- Bring Claude Code or its terminal host to the front
- Grant Accessibility if you want direct frontmost-app control
- Open a prompt that expects confirmation
- Arm ClaudeNod
- Nod to accept or shake to reject

## Permissions

ClaudeNod only needs macOS Accessibility and Screen Recording permissions for the fallback mode that inspects and controls an already-open host app.

If you use the wrapper path, you can skip those permissions entirely.

For fallback mode, you can open the relevant settings from inside the app, or go manually to:

`System Settings > Privacy & Security > Accessibility`

For the most reliable permission behavior, run the bundled app target from `ClaudeNod.xcodeproj` instead of the old Swift package executable.

## Roadmap

### v1

- [x] Native macOS menu bar app
- [x] AirPods motion streaming
- [x] Nod and shake detection
- [x] Configurable accept and reject payloads
- [x] Safe one-shot armed mode
- [x] Automatic detection of likely Claude confirmation prompts
- [x] Wrapper mode that reads Claude output directly
- [ ] Better calibration UX
- [ ] Polished app icon and onboarding

### v1.1

- [ ] Optional `always allow` gesture
- [ ] Per-host action mappings
- [ ] Better confidence scoring and gesture debug UI
- [ ] Signed builds and simple release packaging

## Contributing

Issues and fun ideas are welcome. If you try it with different AirPods or terminal setups, feedback is especially useful because gesture tuning will vary a lot in the real world.

## License

MIT
