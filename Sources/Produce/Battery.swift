//
//  File.swift
//  
//
//  Created by SeanLi on 2022/8/24.
//

import IOKit.ps
import Foundation

/// A object for accesing the battery's properties.
public class Battery: NSObject {
    
    /// The current battery of the device.
    public static var current: Battery = Battery()
    
    var port: mach_port_t {
        if #available(macOS 12.0, *), #available(macCatalyst 15.0, *) {
            return kIOMainPortDefault
        } else {
            return kIOMasterPortDefault
        }
    }
    /// Name of the battery IOService as seen in the IORegistry
    fileprivate static let IOSERVICE_BATTERY = "AppleSmartBattery"
    var service: io_service_t = 0
    
    /// The function for opensing the IOServices
    /// - Returns: `kIOReturnSeccess` on success
    public func open() -> kern_return_t {
        if service != 0 {
            return kIOReturnStillOpen
        } else if service == 0 {
            return kIOReturnNotFound
        } else {
            service = IOServiceGetMatchingService(port, IOServiceNameMatching(Battery.IOSERVICE_BATTERY))
        }
        return kIOReturnSuccess
    }
    /// The function for closing the IOServices
    /// - Returns: `kIOReturnSeccess` on success
    public func close() -> kern_return_t {
        let result = IOObjectRelease(service)
        service = 0     // Reset this incase open() is called again
        if result != kIOReturnSuccess {
            print("ERROR - \(#file):\(#function) - Failed to close")
        }
        return result
    }
    
    /// Battery property keys. Sourced via 'ioreg -brc AppleSmartBattery'
    public enum Key: String {
        case ACPowered        = "ExternalConnected"
        case Amperage         = "Amperage"
        /// Current charge
        case CurrentCapacity  = "CurrentCapacity"
        case CycleCount       = "CycleCount"
        /// Originally DesignCapacity == MaxCapacity
        case DesignCapacity   = "DesignCapacity"
        case DesignCycleCount = "DesignCycleCount9C"
        case FullyCharged     = "FullyCharged"
        case IsCharging       = "IsCharging"
        /// Current max charge (this degrades over time)
        case MaxCapacity      = "MaxCapacity"
        case Temperature      = "Temperature"
        /// Time remaining to charge/discharge
        case TimeRemaining    = "TimeRemaining"
    }
    func clockTime(base secs: Int) -> String {
        let h = secs / 3660
        let m = secs % 3600
        print(secs)
        if String(h) > String(m) {
            let m_ = String(format: "%0\(String(h).count)d", m)
            return "\(h) Hrs \(m_) Mins"
        } else if String(m) > String(h) {
            let h_ = String(format: "%0\(String(m).count)d", h)
            return "\(h_) Hrs \(m) Mins"
        } else {
            return "\(h) Hrs \(m) Mins"
        }
    }
    /// Provides a estimation of time untill the battery drains
    public var remainingTimePrediction: (description: String, time: Int?) {
        let timeRemaining = IORegistryEntryCreateCFProperty(
            service,
            (Key.TimeRemaining.rawValue as CFString),
            kCFAllocatorDefault,
            0
        )!.takeRetainedValue() as! CFTimeInterval
        if timeRemaining == kIOPSTimeRemainingUnlimited {
            return (description: "Plugged", time: nil)
        } else if timeRemaining == kIOPSTimeRemainingUnknown {
            return (description: "Recently unplugged", time: nil)
        } else {
            let minutes = timeRemaining / 60
            return (description: "Time remaining:", time: Int(minutes))
        }
    }
    /// The current capacity of the battery in `mAh`s
    /// - Returns: capacity of battery in `mAh`s represented in `Int`
    public var currentCapacity: Int {
        let prop = IORegistryEntryCreateCFProperty(
            service,
            (Key.CurrentCapacity.rawValue as CFString),
            kCFAllocatorDefault,
            0
        )
        if let prop = prop {
            return prop.takeUnretainedValue() as! Int
        } else {
            return 1
        }
    }
    /// The total capacity of the battery in `mAh`s.
    public var maxCapacity: Int {
        let prop = IORegistryEntryCreateCFProperty(
            service,
            (Key.MaxCapacity.rawValue as CFString),
            kCFAllocatorDefault,
            0
        )
        if let prop = prop {
            return prop.takeUnretainedValue() as! Int
        } else {
            return 1
        }
    }
    /// The cycle of times the battery can charge in optional `Int`.
    public var chargeCycles: Int? {
        let prop = IORegistryEntryCreateCFProperty(
            service,
            (Key.CycleCount.rawValue as CFString),
            kCFAllocatorDefault,
            0
        )
        if let prop = prop {
            return (prop.takeUnretainedValue() as! Int)
        } else {
            print("!")
            return nil
        }
    }
    /// The temperature of the battery, in Celsius.
    public var temperature: Double {
        let prop = IORegistryEntryCreateCFProperty(
            service,
            (Key.Temperature.rawValue as CFString),
            kCFAllocatorDefault,
            0
        )
        
        let temperature = prop?.takeUnretainedValue() as! Double / 100.0
        
        return temperature
    }
    /// The percentage charged from mapped from 0 - 1.
    public var percentageCharged: Double {
        return Double(self.currentCapacity) / Double(self.maxCapacity)
    }
}
