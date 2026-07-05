import AppKit
import Testing
@testable import HoldMac

struct ShakeDragRecognizerTests {
    @Test
    func doesNotTriggerBeforeDragIntentIsEstablished() {
        var recognizer = ShakeDragRecognizer()
        let start = NSPoint(x: 100, y: 100)
        let points = [
            NSPoint(x: 112, y: 100),
            NSPoint(x: 98, y: 100),
            NSPoint(x: 114, y: 100),
            NSPoint(x: 96, y: 100),
            NSPoint(x: 116, y: 100),
            NSPoint(x: 94, y: 100)
        ]

        for point in points {
            let didTrigger = recognizer.update(
                with: point,
                from: start,
                dragTriggerThreshold: 10,
                shakeAmplitude: 72
            )
            #expect(!didTrigger)
        }
    }

    @Test
    func triggersAfterClearDragIntentAndShakeReversals() {
        var recognizer = ShakeDragRecognizer()
        let start = NSPoint(x: 100, y: 100)
        let points = [
            NSPoint(x: 142, y: 100),
            NSPoint(x: 166, y: 100),
            NSPoint(x: 138, y: 100),
            NSPoint(x: 168, y: 100),
            NSPoint(x: 136, y: 100),
            NSPoint(x: 170, y: 100)
        ]

        var didTrigger = false
        for point in points {
            didTrigger = recognizer.update(
                with: point,
                from: start,
                dragTriggerThreshold: 10,
                shakeAmplitude: 72
            ) || didTrigger
        }

        #expect(didTrigger)
    }

    @Test
    func resetClearsPreviousShakeProgress() {
        var recognizer = ShakeDragRecognizer()
        let start = NSPoint(x: 100, y: 100)

        _ = recognizer.update(with: NSPoint(x: 142, y: 100), from: start, dragTriggerThreshold: 10, shakeAmplitude: 72)
        _ = recognizer.update(with: NSPoint(x: 166, y: 100), from: start, dragTriggerThreshold: 10, shakeAmplitude: 72)
        _ = recognizer.update(with: NSPoint(x: 138, y: 100), from: start, dragTriggerThreshold: 10, shakeAmplitude: 72)
        recognizer.reset()

        let didTrigger = recognizer.update(
            with: NSPoint(x: 166, y: 100),
            from: start,
            dragTriggerThreshold: 10,
            shakeAmplitude: 72
        )
        #expect(!didTrigger)
    }
}
