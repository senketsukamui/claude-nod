# ClaudeNod

ClaudeNod is a tiny macOS utility that turns AirPods head gestures into accept and reject actions for Claude Code prompts.

## What v1 does

- Streams head motion from supported AirPods with `CMHeadphoneMotionManager`
- Detects a simple nod or shake with lightweight heuristics
- Arms a one-shot approval action from the menu bar
- Sends configurable accept and reject input to the frontmost supported Claude Code host

## Why the first version is armed

The biggest product risk is accidental approvals. v1 keeps the demo safe by requiring you to arm the next action manually before a nod or shake can send anything.

That gives us a usable product now while leaving room for smarter Claude prompt detection in v1.1.

## Current supported hosts

- Terminal
- iTerm
- Warp
- Claude desktop, if the confirmation field is focused

## Build

1. Open this Swift package in Xcode.
2. Choose the `ClaudeNod` executable target.
3. Run it on macOS with supported AirPods connected.
4. Grant Accessibility permission when prompted.

You can also build from Terminal:

```bash
swift build
```

## Repo roadmap

### v1

- [x] Menu bar utility shell
- [x] AirPods motion streaming
- [x] Nod and shake detection
- [x] Configurable payloads
- [ ] Detect Claude confirmation state automatically
- [ ] Better onboarding and packaging

### v1.1

- [ ] Optional "always allow" gesture
- [ ] Stronger gesture calibration
- [ ] Per-host key mapping
- [ ] Signed release build
