//
//  main.swift
//  PythonTool
//
//  Created by Pedro José Pereira Vieito on 29/1/18.
//  Copyright © 2018 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import LoggerKit
import ArgumentParser
import PythonKit

struct PythonTool: ParsableCommand {
    static var configuration: CommandConfiguration {
        return CommandConfiguration(commandName: String(describing: Self.self))
    }
    
    @Flag(name: .shortAndLong, help: "List installed modules.")
    var list: Bool

    @Flag(name: .shortAndLong, help: "List Python paths.")
    var path: Bool

    @Flag(name: .shortAndLong, help: "Verbose mode.")
    var verbose: Bool

    func run() throws {
        do {
            Logger.logMode = .commandLine
            Logger.logLevel = self.verbose ? .debug : .info

            let pythonVersion = OperatingSystemVersion(
                majorVersion: Int(Python.versionInfo.major) ?? 0,
                minorVersion: Int(Python.versionInfo.minor) ?? 0,
                patchVersion: Int(Python.versionInfo.micro) ?? 0
            )
            
            Logger.log(important: "Python \(pythonVersion.shortVersion)")
            Logger.log(info: "Version: \(pythonVersion)")
            Logger.log(verbose: "Version String: \(Python.version.splitlines()[0])")

            let sys = try Python.attemptImport("sys")
            
            Logger.log(verbose: "Executable: \(sys.executable)")
            Logger.log(verbose: "Executable Prefix: \(sys.exec_prefix)")
            
            if self.path {
                Logger.log(important: "Python Paths (\(sys.path.count))")
                
                if !sys.path.isEmpty {
                    for searchPath in sys.path {
                        Logger.log(success: searchPath)
                    }
                }
                else {
                    Logger.log(warning: "No paths available.")
                }
            }
            
            if self.list {
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
                    Logger.log(warning: "No modules available.")
                }
            }
        }
        catch {
            Logger.log(fatalError: error)
        }
    }
}

PythonTool.main()
