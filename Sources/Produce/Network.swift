//
//  Network.swift
//  
//
//  Created by SeanLi on 2022/8/25.
//

import Cocoa
import Darwin

/// An object for acessing the network of the device.
public class Network: NSObject {
    
    /// The current network of this device.
    public static var current: Network = Network()
    
    /// The device's IP address.
    public var ip: String? {
        let result = shell("ifconfig en0 | grep inet' ' | cut -d' ' -f 2")
        if result == "ifconfig: interface en0 does not exist" {
            return nil
        }
        return result
    }
    
    /// The device's MAC address.
    public var getMacAddress: String? {
        let result = shell("ifconfig en0 | grep ether' ' | cut -d' ' -f 2")
        if result == "ifconfig: interface en0 does not exist" {
            return nil
        }
        return result
    }
}
