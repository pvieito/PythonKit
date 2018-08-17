//
//  main.swift
//  PythonTool
//
//  Created by Pedro José Pereira Vieito on 29/1/18.
//  Copyright © 2018 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import LoggerKit
import CommandLineKit
import PythonKit

let listOption = BoolOption(shortFlag: "l", longFlag: "list", helpMessage: "List installed modules.")
let pathOption = BoolOption(shortFlag: "p", longFlag: "path", helpMessage: "List Python paths.")
let verboseOption = BoolOption(shortFlag: "v", longFlag: "verbose", helpMessage: "Verbose mode.")
let helpOption = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Prints a help message.")

let cli = CommandLineKit.CommandLine()
cli.addOptions(listOption, pathOption, verboseOption, helpOption)

do {
    try cli.parse(strict: true)
}
catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

if helpOption.value {
    cli.printUsage()
    exit(-1)
}

Logger.logMode = .commandLine
Logger.logLevel = verboseOption.value ? .debug : .info

do {
    let sys = try Python.attemptImport("sys")
        
    let pythonVersion =
        OperatingSystemVersion(majorVersion: Int(sys.version_info.major) ?? 0,
                               minorVersion: Int(sys.version_info.minor) ?? 0,
                               patchVersion: Int(sys.version_info.micro) ?? 0)
    
    Logger.log(important: "Python \(pythonVersion.shortVersion)")
    Logger.log(info: "Version: \(pythonVersion)")
    Logger.log(verbose: "Executable: \(sys.executable)")
    Logger.log(verbose: "Executable Prefix: \(sys.exec_prefix)")
    Logger.log(verbose: "Version String:\n\(sys.version)")
    
    if pathOption.value {
        
        Logger.log(important: "Python Paths (\(sys.path.count))")
        
        if !sys.path.isEmpty {
            for searchPath in sys.path {
                Logger.log(success: searchPath)
            }
        }
        else {
            Logger.log(warning: "No paths avaliable.")
        }
    }
    
    if listOption.value {
        
        let pkg_resources = try Python.attemptImport("pkg_resources")
        
        let installedModules = Dictionary<String, PythonObject>(pkg_resources.working_set.by_key)!
        
        Logger.log(important: "Python Modules (\(installedModules.count))")
        
        if !installedModules.isEmpty {
            let installedModulesArray = installedModules.sorted { $0.key.lowercased() < $1.key.lowercased() }
            
            for (_, moduleReference) in installedModulesArray {
                Logger.log(success: "\(moduleReference.key) (\(moduleReference.version))")
            }
        }
        else {
            Logger.log(warning: "No modules avaliable.")
        }
    }
}
catch {
    Logger.log(error: error)
}
