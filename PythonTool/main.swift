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

let sysModule = Python.import("sys")!

let sysPaths = sysModule.get(member: "path")

sysPaths.call(member: "insert", args: 0, "/usr/local/lib/python2.7/site-packages")

let pythonVersionInfo = sysModule.get(member: "version_info")
let pythonVersion =
OperatingSystemVersion(majorVersion: Int(pythonVersionInfo.get(member: "major"))!,
                       minorVersion: Int(pythonVersionInfo.get(member: "minor"))!,
                       patchVersion: Int(pythonVersionInfo.get(member: "micro"))!)

Logger.log(important: "Python \(pythonVersion.shortVersion)")
Logger.log(info: "Version: \(pythonVersion)")
Logger.log(verbose: "Version String:\n\(sysModule.get(member: "version"))")

if pathOption.value {
    
    if !sysPaths.isEmpty {
        Logger.log(important: "Python Paths (\(sysPaths.count))")
        
        for sysPath in sysPaths {
            Logger.log(success: sysPath)
        }
    }
}

if listOption.value {

    guard let pipModule = Python.import("pip") else {
        Logger.log(error: "Module “pip” not available.")
        exit(-1)
    }
    
    let installedModules = pipModule.call(member: "get_installed_distributions")
    
    if !installedModules.isEmpty {
        Logger.log(important: "Python Modules (\(installedModules.count))")
        
        for installedModule in installedModules {
            Logger.log(success: installedModule)
        }
    }
}
