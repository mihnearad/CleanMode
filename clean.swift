import Foundation
import CoreGraphics

print("\n✨ KEYBOARD CLEANER CLI (v2) ✨")
print("------------------------------")
print("How many seconds should the keyboard stay locked?")
print("Enter duration (default: 30): ", terminator: "")

let input = readLine() ?? ""
let lockDuration: TimeInterval = TimeInterval(input) ?? 30

print("\nLocking mouse + keyboard for \(Int(lockDuration)) seconds.")
print("Press [ENTER] to start the 5-second countdown (or Ctrl+C to cancel).")

_ = readLine()

print("Starting in 5...")
Thread.sleep(forTimeInterval: 1)
print("4...")
Thread.sleep(forTimeInterval: 1)
print("3...")
Thread.sleep(forTimeInterval: 1)
print("2...")
Thread.sleep(forTimeInterval: 1)
print("1...")
Thread.sleep(forTimeInterval: 1)

// 1. FREEZE MOUSE (Hardware Level)
// This disconnects the mouse movement from the cursor. Cursor stays put.
CGAssociateMouseAndMouseCursorPosition(0)

print("\n🔒 LOCKED! CLEAN NOW! (\(Int(lockDuration))s remaining)")

// Mask: We want to intercept almost everything
var eventMask: UInt64 = 0
eventMask |= (1 << CGEventType.keyDown.rawValue)
eventMask |= (1 << CGEventType.keyUp.rawValue)
eventMask |= (1 << CGEventType.flagsChanged.rawValue)
eventMask |= (1 << CGEventType.leftMouseDown.rawValue)
eventMask |= (1 << CGEventType.leftMouseUp.rawValue)
eventMask |= (1 << CGEventType.rightMouseDown.rawValue)
eventMask |= (1 << CGEventType.rightMouseUp.rawValue)
eventMask |= (1 << CGEventType.mouseMoved.rawValue)
eventMask |= (1 << CGEventType.leftMouseDragged.rawValue)
eventMask |= (1 << CGEventType.rightMouseDragged.rawValue)
eventMask |= (1 << CGEventType.scrollWheel.rawValue)
eventMask |= (1 << CGEventType.otherMouseDown.rawValue)
eventMask |= (1 << CGEventType.otherMouseUp.rawValue)
eventMask |= (1 << CGEventType.otherMouseDragged.rawValue)
eventMask |= (1 << CGEventType.tabletPointer.rawValue)
eventMask |= (1 << CGEventType.tabletProximity.rawValue)

var eventTapRef: CFMachPort?

func callback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    // Handle tap disabled events - re-enable the tap
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = eventTapRef {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return nil
    }

    // Swallow all input events (keys, mouse, modifiers)
    return nil
}

// Create the Event Tap
guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: callback,
    userInfo: nil
) else {
    print("\n❌ ERROR: Could not create Event Tap.")
    print("Please ensure you have granted 'Accessibility' permissions to your terminal.")
    // Ensure we unfreeze mouse if we fail
    CGAssociateMouseAndMouseCursorPosition(1)
    exit(1)
}

// Store reference for re-enabling in callback
eventTapRef = eventTap

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

// Variables for timing
var remainingTime = lockDuration
let tickRate = 0.1

// Helper to exit cleanly
func cleanupAndExit() {
    print("\n\n🔓 UNLOCKING...")
    // Restore mouse movement
    CGAssociateMouseAndMouseCursorPosition(1)
    exit(0)
}

// Catch Ctrl+C (SIGINT) to ensure we unfreeze mouse even if user force-quits via terminal
signal(SIGINT) { _ in
    CGAssociateMouseAndMouseCursorPosition(1)
    print("\nForce Quit Detected. Mouse unlocked.")
    exit(0)
}

Timer.scheduledTimer(withTimeInterval: tickRate, repeats: true) { timer in
    // Countdown
    remainingTime -= tickRate
    if abs(remainingTime.truncatingRemainder(dividingBy: 1.0)) < tickRate {
        let secondsLeft = Int(round(remainingTime))
        if secondsLeft > 0 {
             print("\r⏳ Cleaning... \(secondsLeft)s left    ", terminator: "")
             fflush(stdout)
        }
    }

    if remainingTime <= 0 {
        cleanupAndExit()
    }
}

CFRunLoopRun()
