import Foundation
import Darwin.Mach

final class MemoryService {
    func read() -> MemoryMetrics {
        let total = ProcessInfo.processInfo.physicalMemory

        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var stats = vm_statistics64_data_t()
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryMetrics(usedBytes: 0, totalBytes: total, pressure: 0)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let free = UInt64(stats.free_count) * pageSize
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        let used = active + inactive + wired + compressed
        let pressure = total > 0 ? Double(total - free) / Double(total) : 0
        return MemoryMetrics(usedBytes: used, totalBytes: total, pressure: max(0, min(1, pressure)))
    }
}
