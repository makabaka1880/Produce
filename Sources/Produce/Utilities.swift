//
//  File.swift
//  
//
//  Created by SeanLi on 2022/8/24.
//

import Foundation

func shell(_ command: String, lauchPath: String = "/bin/zsh") -> String? {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .newlines)
    
    return output
}

