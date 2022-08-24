//
//  File.swift
//  
//
//  Created by SeanLi on 2022/8/24.
//

import MachO
import Foundation


private let HOST_BASIC_INFO_COUNT: mach_msg_type_number_t = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_LOAD_INFO_COUNT: mach_msg_type_number_t = UInt32(MemoryLayout<host_load_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_CPU_LOAD_INFO_COUNT: mach_msg_type_number_t = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_VM_INFO64_COUNT: mach_msg_type_number_t = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
private let HOST_SCHED_INFO_COUNT: mach_msg_type_number_t = UInt32(MemoryLayout<host_sched_info_data_t>.size / MemoryLayout<integer_t>.size)
private let PROCESSOR_SET_LOAD_INFO_COUNT: mach_msg_type_number_t = UInt32(MemoryLayout<processor_set_load_info_data_t>.size / MemoryLayout<natural_t>.size)

/// A enumeration of most commonly seen architecture
public enum ProcresserArch: String {
    case any = "Unknown Architecture"
    case ARM = "ARM"
    case ARM64 = "ARM64"
    case ARM64_32 = "ARM64_32"
    case x86 = "x86"
    case x86_64 = "x86_64"
    case VAX = "VAX"
    case MC680x0 = "MC680x0"
    case I386 = "I386"
    case MC98000 = "MC98000"
    case HPPA = "HPPA"
    case MC88000 = "MC88000"
    case SPARC = "SPAPRC"
    case I860 = "I860"
    case PowerPC = "PowerPC"
    case PowerPC64 = "PowerPC64"
}
/// A object for accesing the Central Processing Unit's properties.
public class CentralProcessor: NSObject {
    /// The current CPU of the device.
    public static let current: CentralProcessor = CentralProcessor()
    fileprivate static let machHost = mach_host_self()
    fileprivate var loadPrevious = host_cpu_load_info()
    // MARK: preparation
    fileprivate func hostBasicInfo() -> host_basic_info {
        var size = HOST_BASIC_INFO_COUNT
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_info(CentralProcessor.machHost, HOST_BASIC_INFO, $0, &size)
        }
        debugPrint("\(#file): \(result) returned by hostInfo.withMemoryRebound(to:capacity:body:)")
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }
    fileprivate static func hostCPULoadInfo() -> host_cpu_load_info {
        var size = HOST_CPU_LOAD_INFO_COUNT
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(machHost, HOST_CPU_LOAD_INFO, $0, &size)
        }
        debugPrint("\(#file): \(result) returned by hostInfo.withMemoryRebound(to:capacity:body:)")
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
        
    }
    // MARK: Arch
    /// Creates a instance of ``ProcresserArch``.
    /// - Parameters:
    ///     - for: cpu_type_t, the arch in `cpu_type_t` code
    public static func archRepresentation(for code: cpu_type_t) -> ProcresserArch {
        switch code {
        case CPU_TYPE_ANY:
            return .any
        case CPU_TYPE_ARM:
            return .ARM
        case CPU_TYPE_ARM64:
            return .ARM64
        case CPU_TYPE_ARM64_32:
            return .ARM64_32
        case CPU_TYPE_X86:
            return .x86
        case CPU_TYPE_X86_64:
            return .x86_64
        case CPU_TYPE_VAX:
            return .VAX
        case CPU_TYPE_MC680x0:
            return .MC680x0
        case CPU_TYPE_I386:
            return .I386
        case CPU_TYPE_MC98000:
            return .MC98000
        case CPU_TYPE_HPPA:
            return .HPPA
        case CPU_TYPE_MC88000:
            return .MC88000
        case CPU_TYPE_SPARC:
            return .SPARC
        case CPU_TYPE_I860:
            return .I860
        case CPU_TYPE_POWERPC:
            return .PowerPC
        case CPU_TYPE_POWERPC64:
            return .PowerPC64
        default:
            return .any
        }
    }
    // MARK: physicalCores
    /// Provides the number of pysical cores the processer has
    public var physicalCores: Int {
        return Int(CentralProcessor.init().hostBasicInfo().physical_cpu)
    }
    
    // MARK: logicalCores
    /// Provides the number of logical cores the processer has.
    public var logicalCores: Int {
        return Int(CentralProcessor.init().hostBasicInfo().logical_cpu)
    }
    
    // MARK: usage
    /// Provides the number of usage of the processer
    /// - Returns: a tuple that of this format: (system: Double, user: Double, idle: Double, nice: Double)
    public var usage: (system: Double, user: Double, idle: Double, nice: Double) {
        let load = CentralProcessor.hostCPULoadInfo()
        let userDiff = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
        let sysDiff  = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
        let idleDiff = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
        let niceDiff = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)

        let totalTicks = sysDiff + userDiff + niceDiff + idleDiff

        let sys  = sysDiff  / totalTicks * 100.0
        let user = userDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0

        loadPrevious = load
        return (sys, user, idle, nice)
    }
    // MARK: arch(_ pid:)
    /// What architecture was this process compiled for?
    /// - Parameters:
    ///     - <NUNNAMED>: `pid_t`, the pid of the process. Default is 0, the kernel.
    /// - Returns: A ``ProcresserArch`` representation of the arch compiled for that process.
    public func arch(_ pid: pid_t = 0) -> ProcresserArch {
        var arch = CPU_TYPE_ANY
        
        // sysctl.proc_cputype not documented anywhere. Doesn't even show up
        // when running 'sysctl -A'. Have to call sysctlnametomib() before hand
        // due to this
        // TODO: Call sysctlnametomib() only once
        var mib       = [Int32](repeating: 0, count: Int(CTL_MAXNAME))
        var mibLength = size_t(CTL_MAXNAME)
        
        var result = sysctlnametomib("sysctl.proc_cputype", &mib, &mibLength)

        if result != 0 {
            #if DEBUG
                print("ERROR - \(#file):\(#function):\(#line) - "
                        + "\(result)")
            #endif

            return CentralProcessor.archRepresentation(for: arch)
        }
        
        
        mib[Int(mibLength)] = pid
        var size = MemoryLayout<cpu_type_t>.size

        result = sysctl(&mib, u_int(mibLength + 1), &arch, &size, nil, 0)

        if result != 0 {
            #if DEBUG
                print("ERROR - \(#file):\(#function):\(#line) - "
                        + "\(result)")
            #endif

            arch = CPU_TYPE_ANY
        }
        return CentralProcessor.archRepresentation(for: arch)
    }
}
