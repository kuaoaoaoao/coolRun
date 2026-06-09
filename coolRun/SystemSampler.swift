import Foundation
import Darwin

#if os(macOS)
import IOKit.ps
#elseif canImport(UIKit)
import UIKit
#endif

final class SystemSampler {
    private var previousCPUTicks: [UInt32]?

    func sample() -> SystemSnapshot {
        SystemSnapshot(
            cpu: sampleCPU(),
            memory: sampleMemory(),
            storage: sampleStorage(),
            battery: sampleBattery(),
            network: sampleNetwork(),
            updatedAt: Date()
        )
    }

    private func sampleCPU() -> CPUMetrics {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &load) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return CPUMetrics(coreCount: ProcessInfo.processInfo.activeProcessorCount)
        }

        let ticks = [
            UInt32(load.cpu_ticks.0),
            UInt32(load.cpu_ticks.1),
            UInt32(load.cpu_ticks.2),
            UInt32(load.cpu_ticks.3)
        ]

        defer { previousCPUTicks = ticks }

        guard let previousCPUTicks else {
            return CPUMetrics(usage: 0, coreCount: ProcessInfo.processInfo.activeProcessorCount)
        }

        let deltas = zip(ticks, previousCPUTicks).map { current, previous in
            Double(current >= previous ? current - previous : 0)
        }
        let idle = deltas[Int(CPU_STATE_IDLE)]
        let total = deltas.reduce(0, +)
        let usage = total > 0 ? (total - idle) / total : 0

        return CPUMetrics(
            usage: min(max(usage, 0), 1),
            coreCount: ProcessInfo.processInfo.activeProcessorCount
        )
    }

    private func sampleMemory() -> MemoryMetrics {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryMetrics(total: ProcessInfo.processInfo.physicalMemory)
        }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        let pageBytes = UInt64(pageSize)
        let usedPages = UInt64(stats.active_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.compressor_page_count)

        return MemoryMetrics(
            used: usedPages * pageBytes,
            total: ProcessInfo.processInfo.physicalMemory
        )
    }

    private func sampleStorage() -> StorageMetrics {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser

        guard
            let values = try? url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
        else {
            return StorageMetrics()
        }

        let total = UInt64(max(values.volumeTotalCapacity ?? 0, 0))
        let available = UInt64(max(values.volumeAvailableCapacityForImportantUsage ?? 0, 0))

        return StorageMetrics(
            used: total > available ? total - available : 0,
            total: total
        )
    }

    private func sampleBattery() -> BatteryMetrics {
        var metrics = BatteryMetrics(
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )

        #if os(macOS)
        guard
            let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
            let source = sources.first,
            let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue()
                as? [String: Any]
        else {
            metrics.state = .noBattery
            return metrics
        }

        let current = description[kIOPSCurrentCapacityKey] as? Double
        let max = description[kIOPSMaxCapacityKey] as? Double
        if let current, let max, max > 0 {
            metrics.level = current / max
        }

        let state = description[kIOPSPowerSourceStateKey] as? String
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        if isCharging {
            metrics.state = .charging
        } else if let level = metrics.level, level >= 0.995 {
            metrics.state = .full
        } else if state == kIOPSACPowerValue {
            metrics.state = .full
        } else {
            metrics.state = .unplugged
        }
        #elseif canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level >= 0 {
            metrics.level = Double(level)
        }

        switch UIDevice.current.batteryState {
        case .unplugged:
            metrics.state = .unplugged
        case .charging:
            metrics.state = .charging
        case .full:
            metrics.state = .full
        case .unknown:
            metrics.state = .unknown
        @unknown default:
            metrics.state = .unknown
        }
        #else
        metrics.state = .unknown
        #endif

        return metrics
    }

    private func sampleNetwork() -> NetworkMetrics {
        let status = currentNetworkStatus()
        return NetworkMetrics(
            activeInterfaceCount: status.activeInterfaceCount,
            primaryAddress: status.primaryAddress
        )
    }

    private func currentNetworkStatus() -> NetworkStatus {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let interfaces else {
            return NetworkStatus()
        }
        defer { freeifaddrs(interfaces) }

        var status = NetworkStatus()
        var cursor: UnsafeMutablePointer<ifaddrs>? = interfaces
        var activeNames = Set<String>()

        while let interface = cursor {
            defer { cursor = interface.pointee.ifa_next }

            let flags = Int32(interface.pointee.ifa_flags)
            guard flags & IFF_UP == IFF_UP, flags & IFF_LOOPBACK == 0 else {
                continue
            }

            let name = String(cString: interface.pointee.ifa_name)
            activeNames.insert(name)

            if status.primaryAddress == nil,
               let address = interface.pointee.ifa_addr,
               address.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    address,
                    socklen_t(address.pointee.sa_len),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                if result == 0 {
                    status.primaryAddress = String(cString: host)
                }
            }
        }

        status.activeInterfaceCount = activeNames.count
        return status
    }
}

private struct NetworkStatus {
    var activeInterfaceCount: Int = 0
    var primaryAddress: String?
}
