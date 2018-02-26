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
    let sys = try Python.import("sys")
    
    let sysPaths = sys.get(member: "path")
    
    sysPaths.call(member: "insert", 0, "/usr/local/lib/python2.7/site-packages")
    
    let pythonVersionInfo = sys.get(member: "version_info")
    let pythonVersion =
        OperatingSystemVersion(majorVersion: Int(pythonVersionInfo.get(member: "major"))!,
                               minorVersion: Int(pythonVersionInfo.get(member: "minor"))!,
                               patchVersion: Int(pythonVersionInfo.get(member: "micro"))!)
    
    Logger.log(important: "Python \(pythonVersion.shortVersion)")
    Logger.log(info: "Version: \(pythonVersion)")
    Logger.log(verbose: "Version String:\n\(sys.get(member: "version"))")
    
    if pathOption.value {
        
        Logger.log(important: "Python Paths (\(sysPaths.count))")

        if !sysPaths.isEmpty {
            for sysPath in sysPaths {
                Logger.log(success: sysPath)
            }
        }
        else {
            Logger.log(warning: "No paths avaliable.")
        }
    }
    
    if listOption.value {
        
        guard let pipModule = try? Python.import("pip") else {
            Logger.log(error: "Module “pip” not available.")
            exit(-1)
        }
        
        let installedModules = pipModule.call(member: "get_installed_distributions")
        
        Logger.log(important: "Python Modules (\(installedModules.count))")
        
        if !installedModules.isEmpty {
            for installedModule in installedModules {
                Logger.log(success: installedModule)
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
