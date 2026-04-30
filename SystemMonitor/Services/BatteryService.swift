import Foundation
import IOKit.ps

final class BatteryService {
    func readBattery() -> BatteryMetrics {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatteryMetrics(level: nil, isCharging: nil)
        }

        let current = (description[kIOPSCurrentCapacityKey as String] as? Double) ?? 0
        let max = (description[kIOPSMaxCapacityKey as String] as? Double) ?? 0
        let charging = description[kIOPSIsChargingKey as String] as? Bool
        return BatteryMetrics(level: max > 0 ? current / max : nil, isCharging: charging)
    }

    func readTemperature() -> TemperatureMetrics {
        TemperatureMetrics(celsius: nil)
    }
}
