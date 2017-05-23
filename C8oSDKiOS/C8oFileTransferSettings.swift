//
//  C8oFileTransferSettings.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 13/07/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oFileTransferSettings : C8oFileTransferBase{
    public override init() {
        super.init()
    }
    
    public init(c8oFileTransferSettings : C8oFileTransferSettings) {
        super.init()
        copy(c8oFileTransferSettings)
    }
    
    open func setProjectName(_ projectName: String) -> C8oFileTransferSettings {
        _projectName = projectName
        return self
    }
    
    open func setTaskDb(_ taskDb: String) -> C8oFileTransferSettings {
        _taskDb = taskDb
        return self
    }
    
    open func setMaxRunning(_ maxRunning: Int) -> C8oFileTransferSettings {
        if (maxRunning > 0) {
            _maxRunning = maxRunning
        }
        return self
    }
    
    open func setMaxDurationForTransferAttempt(_ maxDurationForTransferAttempt: TimeInterval) -> C8oFileTransferSettings {
        _maxDurationForTransferAttempt = maxDurationForTransferAttempt
        return self
    }
}
