import Foundation
import IOKit

/// An object for accessing information about your current device.
public struct Device {
    /// The device's name.
    public var name: String? {
        return Host.current().name
    }
    
    /// The device's serial number.
    public var serialNumber: String? {
        var port: mach_port_t!
        if #available(macOS 12.0, *) {
            port = kIOMainPortDefault
        } else {
            port = kIOMasterPortDefault
        }
        let platformExpert = IOServiceGetMatchingService(port, IOServiceMatching("IOPlatformExpertDevice") )
        guard platformExpert > 0 else {
            return nil
        }
        guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            return nil
        }
        IOObjectRelease(platformExpert)
        return serialNumber
    }
    
    
    /// The current CPU of the device.
    public var CPU: CentralProcessor {
        return .current
    }
    
    /// The current CPU of the device.
    public var GPU: GraphicProcessor {
        return .current
    }
    
    /// The current battery of the device.
    public var battery: Battery {
        return .current
    }
    
    /// The current network of the device
    public var network: Network {
        return .current
    }
}
