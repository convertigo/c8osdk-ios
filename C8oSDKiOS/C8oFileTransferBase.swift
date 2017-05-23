//
//  C8oFileTransferBase.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 13/07/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oFileTransferBase{
    internal var _projectName : String = "lib_FileTransfer"
    internal var _taskDb : String = "c8ofiletransfer_tasks"
    internal var _maxDurationForTransferAttempt : TimeInterval = 60 * 20
    internal var _maxRunning : Int = 4
    
    open var projectName : String {
        get { return _projectName }
    }
    
    open var taskDb : String {
        get { return _taskDb }
    }
    
    open var maxRunning : Int {
        get { return _maxRunning }
    }
    
    open var maxDurationForTransferAttempt : TimeInterval {
        get { return _maxDurationForTransferAttempt }
    }
    
    open func copy(_ settings : C8oFileTransferSettings) {
        _projectName = settings._projectName
        _taskDb = settings._taskDb
        _maxRunning = settings._maxRunning
        _maxDurationForTransferAttempt = settings._maxDurationForTransferAttempt
    }
}
