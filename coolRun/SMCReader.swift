//
//  SMCReader.swift
//  coolRun
//
//  读取 macOS SMC (System Management Controller) 数据
//  包括温度传感器
//

import Foundation
import IOKit

#if os(macOS)

// MARK: - SMC 数据结构

/// SMC 返回的数据类型
private struct SMCKeyData {
    var majorType: UInt8 = 0
    var minorType: UInt8 = 0
    var dataSize: UInt32 = 0
    var dataValueType: FourCharCode = 0
    var data: SMCBytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var key: FourCharCode = 0
    var status: UInt8 = 0
    var info: SMCKeyInfo = SMCKeyInfo()
}

private struct SMCKeyInfo {
    var dataSize: UInt32 = 0
    var dataType: FourCharCode = 0
    var dataAttributes: UInt8 = 0
}

private typealias SMCBytes = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

// MARK: - SMC 核心读取器

/// SMC 核心读取器
private final class SMCConnection {
    private var connection: io_connect_t = 0

    init?() {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard service != 0 else { return nil }

        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        IOObjectRelease(service)

        guard result == kIOReturnSuccess else {
            print("[SMCReader] 无法打开 SMC 连接，错误码: \(result)")
            return nil
        }
    }

    deinit {
        if connection != 0 {
            IOServiceClose(connection)
        }
    }

    /// 读取 SMC 值
    func read(key: String) -> Double? {
        guard key.count == 4 else { return nil }

        var input = SMCKeyData()
        var output = SMCKeyData()

        // 第一步：获取 key 信息
        input.key = fourCharCode(from: key)
        input.majorType = 2 // SMC_CMD_READ_KEYINFO

        guard callKernel(input: &input, output: &output) else { return nil }

        let info = output.info
        guard info.dataSize > 0 else { return nil }

        // 第二步：读取数据
        input.majorType = 5 // SMC_CMD_READ_BYTES
        input.info = info

        guard callKernel(input: &input, output: &output) else { return nil }

        // 解析数据
        return parseSMCValue(type: info.dataType, bytes: output.data, size: Int(info.dataSize))
    }

    /// 调用内核
    private func callKernel(input: inout SMCKeyData, output: inout SMCKeyData) -> Bool {
        let inputSize = MemoryLayout<SMCKeyData>.stride
        var outputSize = MemoryLayout<SMCKeyData>.stride

        let result = IOConnectCallStructMethod(
            connection,
            UInt32(2), // KERNEL_INDEX_SMC
            &input,
            inputSize,
            &output,
            &outputSize
        )

        return result == kIOReturnSuccess
    }

    /// 解析 SMC 值
    private func parseSMCValue(type: FourCharCode, bytes: SMCBytes, size: Int) -> Double? {
        switch type {
        case fourCharCode(from: "sp78"):
            // 浮点数 7.8 格式（温度）
            if size >= 2 {
                let sign = Int16(bytes.0)
                let fraction = UInt16(bytes.1)
                return Double(sign) + Double(fraction) / 256.0
            }
        case fourCharCode(from: "flt "):
            // 标准浮点数
            if size >= 4 {
                var value: Float = 0
                withUnsafeMutableBytes(of: &value) { ptr in
                    ptr[0] = bytes.0
                    ptr[1] = bytes.1
                    ptr[2] = bytes.2
                    ptr[3] = bytes.3
                }
                return Double(value)
            }
        case fourCharCode(from: "fpe2"):
            // 浮点数 14.2 格式
            if size >= 2 {
                let value = (UInt16(bytes.0) << 8) | UInt16(bytes.1)
                return Double(value) / 4.0
            }
        case fourCharCode(from: "ui16"):
            // 无符号 16 位整数
            if size >= 2 {
                return Double((UInt16(bytes.0) << 8) | UInt16(bytes.1))
            }
        case fourCharCode(from: "ui32"):
            // 无符号 32 位整数
            if size >= 4 {
                return Double(
                    (UInt32(bytes.0) << 24) |
                    (UInt32(bytes.1) << 16) |
                    (UInt32(bytes.2) << 8) |
                    UInt32(bytes.3)
                )
            }
        case fourCharCode(from: "si16"):
            // 有符号 16 位整数
            if size >= 2 {
                let value = Int16(bitPattern: (UInt16(bytes.0) << 8) | UInt16(bytes.1))
                return Double(value)
            }
        default:
            // 尝试作为 sp78 解析（大多数温度使用此格式）
            if size >= 2 {
                let sign = Int16(bytes.0)
                let fraction = UInt16(bytes.1)
                let value = Double(sign) + Double(fraction) / 256.0
                // 检查是否是合理的温度值 (-100 到 150)
                if value > -100 && value < 150 {
                    return value
                }
            }
        }
        return nil
    }

    /// 将字符串转换为 FourCharCode
    private func fourCharCode(from string: String) -> FourCharCode {
        var code: FourCharCode = 0
        for (index, char) in string.utf8.enumerated() where index < 4 {
            code = code << 8 | FourCharCode(char)
        }
        return code
    }
}

// MARK: - 公开 API

/// 温度传感器读数
struct TemperatureReading: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let temperature: Double // 摄氏度

    var formatted: String {
        String(format: "%.1f°C", temperature)
    }
}

/// SMC 读取器 - 公开接口
final class SMCReader {
    private var connection: SMCConnection?
    private var isAvailable: Bool = false

    init() {
        connection = SMCConnection()
        isAvailable = connection != nil
    }

    /// 检查 SMC 是否可用
    var available: Bool {
        isAvailable
    }

    // MARK: - 温度传感器

    /// 常见温度传感器的 SMC Key
    private static let temperatureKeys: [(key: String, name: String)] = [
        // CPU 温度
        ("TC0P", "CPU 近端"),
        ("TC0D", "CPU 核心"),
        ("TC0E", "CPU"),
        ("TC0F", "CPU"),
        ("TC1C", "CPU 核心 1"),
        ("TC2C", "CPU 核心 2"),
        ("TC3C", "CPU 核心 3"),
        ("TC4C", "CPU 核心 4"),
        ("TC5C", "CPU 核心 5"),
        ("TC6C", "CPU 核心 6"),
        ("TC7C", "CPU 核心 7"),
        ("TC8C", "CPU 核心 8"),
        // GPU 温度
        ("TG0P", "GPU 近端"),
        ("TG0D", "GPU 核心"),
        ("TG0H", "GPU 散热器"),
        // 内存温度
        ("TM0P", "内存 近端"),
        ("TM0S", "内存"),
        // SSD 温度
        ("Ts0P", "SSD"),
        ("Ts1P", "SSD"),
        // 主板温度
        ("Ts0S", "主板"),
        ("Tp01", "主板 近端"),
    ]

    /// 读取所有可用的温度传感器
    func readTemperatures() -> [TemperatureReading] {
        guard let connection = connection else { return [] }

        var readings: [TemperatureReading] = []

        for (key, name) in Self.temperatureKeys {
            if let temp = connection.read(key: key), temp > -40, temp < 150 {
                readings.append(TemperatureReading(name: name, temperature: temp))
            }
        }

        // 去重：相同温度的传感器只保留一个
        var seen = Set<Double>()
        return readings.filter { reading in
            if seen.contains(reading.temperature) {
                return false
            }
            seen.insert(reading.temperature)
            return true
        }
    }

    /// 读取 CPU 温度（取所有 CPU 传感器的平均值）
    func readCPUTemperature() -> Double? {
        guard let connection = connection else { return nil }

        let cpuKeys = ["TC0P", "TC0D", "TC0E", "TC0F", "TC1C", "TC2C", "TC3C", "TC4C"]
        var temps: [Double] = []

        for key in cpuKeys {
            if let temp = connection.read(key: key), temp > 0, temp < 150 {
                temps.append(temp)
            }
        }

        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }

    /// 读取 GPU 温度
    func readGPUTemperature() -> Double? {
        guard let connection = connection else { return nil }

        let gpuKeys = ["TG0P", "TG0D", "TG0H"]
        for key in gpuKeys {
            if let temp = connection.read(key: key), temp > 0, temp < 150 {
                return temp
            }
        }
        return nil
    }

}

#else

// 非 macOS 平台的空实现
final class SMCReader {
    var available: Bool { false }
    func readTemperatures() -> [TemperatureReading] { [] }
    func readCPUTemperature() -> Double? { nil }
    func readGPUTemperature() -> Double? { nil }
}

struct TemperatureReading: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let temperature: Double
    var formatted: String { "" }
}

#endif
