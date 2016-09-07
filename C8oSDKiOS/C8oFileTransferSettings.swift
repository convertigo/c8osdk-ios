//
//  C8oFileTransferSettings.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 13/07/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oFileTransferSettings : C8oFileTransferBase{
    public override init() {
        super.init()
    }
    
    public init(c8oFileTransferSettings : C8oFileTransferSettings) {
        super.init()
        copy(c8oFileTransferSettings)
    }
    
    public func setProjectName(projectName: String) throws -> C8oFileTransferSettings {
        _projectName = projectName
        return self
    }
    
    public func setTaskDb(taskDb: String) throws -> C8oFileTransferSettings {
        _taskDb = taskDb
        return self
    }
    
    public func setMaxRunning(maxRunning: Int) throws -> C8oFileTransferSettings {
        if (maxRunning > 0) {
            _maxRunning = maxRunning
        }
        return self
    }
}