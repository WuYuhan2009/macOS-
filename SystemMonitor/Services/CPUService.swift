import Foundation
import Darwin.Mach

final class CPUService {
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0

    deinit {
        if let previousCPUInfo {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), vm_size_t(previousCPUInfoCount))
        }
    }

    func read() -> CPUMetrics {
        var count: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &cpuInfo, &cpuInfoCount)
        guard result == KERN_SUCCESS, let cpuInfo else {
            return CPUMetrics(totalUsage: 0, coreUsages: [])
        }

        var usages: [Double] = []
        for i in 0..<Int(count) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])

            var totalTicks = user + system + idle + nice
            var idleTicks = idle

            if let previousCPUInfo {
                let pUser = Double(previousCPUInfo[offset + Int(CPU_STATE_USER)])
                let pSystem = Double(previousCPUInfo[offset + Int(CPU_STATE_SYSTEM)])
                let pIdle = Double(previousCPUInfo[offset + Int(CPU_STATE_IDLE)])
                let pNice = Double(previousCPUInfo[offset + Int(CPU_STATE_NICE)])

                totalTicks -= (pUser + pSystem + pIdle + pNice)
                idleTicks -= pIdle
            }

            let usage = totalTicks > 0 ? (totalTicks - idleTicks) / totalTicks : 0
            usages.append(max(0, min(1, usage)))
        }

        if let previousCPUInfo {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), vm_size_t(previousCPUInfoCount))
        }
        previousCPUInfo = cpuInfo
        previousCPUInfoCount = cpuInfoCount

        let total = usages.isEmpty ? 0 : usages.reduce(0, +) / Double(usages.count)
        return CPUMetrics(totalUsage: total, coreUsages: usages)
    }
}
