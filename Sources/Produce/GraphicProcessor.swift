//
//  File.swift
//  
//
//  Created by SeanLi on 2022/8/24.
//

import Foundation
import Metal
import SwiftUI

/// A object for accesing the Graphics Processing Unit's properties.
public class GraphicProcessor: NSObject {
    
    /// The current GPU of the device.
    public static var current: GraphicProcessor = GraphicProcessor()
    
    /// Whether the GPU's info is avaliable or not.
    public var avaliable: Bool {
        if let _ = MTLCreateSystemDefaultDevice() {
            return true
        } else {
            return false
        }
    }
    
    /// The GPU object.
    public var device: MTLDevice? {
        return MTLCreateSystemDefaultDevice()
    }
    
    /// The name of you GPU.
    public var name: String? {
        return device?.name
    }
    
    /// The location of your GPU: Builtin, Slotted, external or can't be specified by the computer?
    public var location: MTLDeviceLocation? {
        return device?.location
    }
    
    /// The number of cores in the GPU. If the device is not in a peer group, returns 0
    public var cores: UInt32? {
        if device?.peerCount == 0 {
            return 1
        } else {
            return device?.peerCount
        }
    }
    
    /// Approxiamatly the best working memory in bytes of the GPU.
    public var recommendedMemoryUsage: UInt64? {
        return device?.recommendedMaxWorkingSetSize
    }
}
