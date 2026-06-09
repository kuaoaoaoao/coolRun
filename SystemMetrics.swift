import Foundation

struct SystemSnapshot: Equatable {
    var cpu = CPUMetrics()
    var memory = MemoryMetrics()
    var storage = StorageMetrics()
    var battery = BatteryMetrics()
    var network = NetworkMetrics()
    var updatedAt = Date()
}

struct CPUMetrics: Equatable {
    var usage: Double = 0
    var coreCount: Int = ProcessInfo.processInfo.activeProcessorCount
}

struct MemoryMetrics: Equatable {
    var used: UInt64 = 0
    var total: UInt64 = ProcessInfo.processInfo.physicalMemory

    var usage: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(used) / Double(total), 0), 1)
    }
}

struct StorageMetrics: Equatable {
    var used: UInt64 = 0
    var total: UInt64 = 0

    var available: UInt64 {
        total > used ? total - used : 0
    }

    var usage: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(used) / Double(total), 0), 1)
    }
}

struct BatteryMetrics: Equatable {
    var level: Double?
    var state: BatteryState = .unknown
    var isLowPowerModeEnabled: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled
}

enum BatteryState: String, Equatable {
    case unknown = "未知"
    case unplugged = "电池供电"
    case charging = "充电中"
    case full = "已充满"
    case noBattery = "无电池"
}

struct NetworkMetrics: Equatable {
    var activeInterfaceCount: Int = 0
    var primaryAddress: String?
}
