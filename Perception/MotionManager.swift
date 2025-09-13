import Foundation
import CoreMotion
import Combine

final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    private let motion = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()

    // Ring buffer: [T, 8] = accel(xyz), gyro(xyz), baro(pressure kPa, altitude m)
    private let seqLen = 300
    private var buffer: [[Float]]
    private var idx: Int = 0
    private var started = false

    private var lastPressureKPa: Float = 101.325
    private var lastAltitudeM: Float = 0.0

    private init() {
        buffer = Array(repeating: Array(repeating: 0.0, count: 8), count: seqLen)
        queue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard !started else { return }
        started = true
        motion.accelerometerUpdateInterval = 1.0 / 50.0
        motion.gyroUpdateInterval = 1.0 / 50.0

        if motion.isAccelerometerAvailable {
            motion.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
                self?.handleAccel(data)
            }
        }
        if motion.isGyroAvailable {
            motion.startGyroUpdates(to: queue) { [weak self] data, _ in
                self?.handleGyro(data)
            }
        }
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, _ in
                guard let d = data else { return }
                // Pressure in kPa, altitude in m
                self?.lastPressureKPa = Float(truncating: d.pressure)
                self?.lastAltitudeM = Float(truncating: d.relativeAltitude)
            }
        }
    }

    func stop() {
        guard started else { return }
        started = false
        motion.stopAccelerometerUpdates()
        motion.stopGyroUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }

    private func handleAccel(_ data: CMAccelerometerData?) {
        guard let d = data else { return }
        writeSample(ax: Float(d.acceleration.x), ay: Float(d.acceleration.y), az: Float(d.acceleration.z), gx: nil, gy: nil, gz: nil)
    }

    private func handleGyro(_ data: CMGyroData?) {
        guard let d = data else { return }
        writeSample(ax: nil, ay: nil, az: nil, gx: Float(d.rotationRate.x), gy: Float(d.rotationRate.y), gz: Float(d.rotationRate.z))
    }

    private func writeSample(ax: Float?, ay: Float?, az: Float?, gx: Float?, gy: Float?, gz: Float?) {
        var row = buffer[idx]
        if let ax = ax { row[0] = ax }
        if let ay = ay { row[1] = ay }
        if let az = az { row[2] = az }
        if let gx = gx { row[3] = gx }
        if let gy = gy { row[4] = gy }
        if let gz = gz { row[5] = gz }
        row[6] = lastPressureKPa
        row[7] = lastAltitudeM
        buffer[idx] = row
        idx = (idx + 1) % seqLen
    }

    // Returns [T, 8] ordered from oldest to newest
    func snapshot() -> [[Float]] {
        var out: [[Float]] = []
        out.reserveCapacity(seqLen)
        let tail = buffer[idx..<seqLen]
        let head = buffer[0..<idx]
        out.append(contentsOf: tail)
        out.append(contentsOf: head)
        return out
    }
}
