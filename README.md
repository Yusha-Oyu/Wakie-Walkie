Wakie Walkie 🚶⏰

A Flutter alarm app that won't turn off until you've actually woken up.

The problem

Traditional alarms are too easy to silence half-asleep — one tap and you're back under the covers. Wakie Walkie solves this by tying the alarm's dismissal to physical movement: the alarm only stops once you've walked a user-configurable number of steps, tracked live via the phone's pedometer sensor. Nothing else can turn it off, so you're forced to actually get up and move before you can go back to sleep.

Features
Set a custom alarm time
Choose how many steps are required to dismiss the alarm
Live step tracking via the device's pedometer sensor
Alarm persists until the step goal is met — no snooze shortcuts
Tech stack
Framework: Flutter / Dart
Sensors: Native pedometer / motion sensor APIs
Technical challenge

Flutter's pedometer plugins wrap native step-counter APIs with very little visibility into what's actually happening under the hood — no raw sensor feed, and inconsistent behavior between the emulator and a real device. Confirming the step count was genuinely tracking (not just stuck or lagging) took building small test harnesses to log and verify step events in real time, then validating against real walking before wiring it into the alarm logic.

Step detection isn't perfect — the sensor occasionally misses steps, so users sometimes have to walk a bit further than the number they set. This is a known limitation of consumer-grade pedometer sensors, and one I'm continuing to tune.

Status

Working build, tested on a physical device.

Author

Solo project — designed, built, and tested end-to-end.
