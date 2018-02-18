//
//  OperatingSystemVersion.swift
//  PythonTool
//
//  Created by Pedro José Pereira Vieito on 29/1/18.
//  Copyright © 2018 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

extension OperatingSystemVersion: CustomStringConvertible {
    
    public var shortVersion: String {
        return "\(self.majorVersion).\(self.minorVersion)"
    }
    
    public var description: String {
        return "\(self.majorVersion).\(self.minorVersion).\(self.patchVersion)"
    }
}
