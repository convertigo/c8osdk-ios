//
//  C8oFileTransferBase.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 13/07/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oFileTransferBase{
    internal var _projectName : String = "lib_FileTransfer"
    internal var _taskDb : String = "c8ofiletransfer_tasks"
    internal var _maxRunning : Int = 4
    
    public var projectName : String {
        get { return _projectName }
    }
    
    public var taskDb : String {
        get { return _taskDb }
    }
    
    public var maxRunning : Int {
        get { return _maxRunning }
    }
    
    public func copy(settings : C8oFileTransferSettings) {
        _projectName = settings._projectName
        _taskDb = settings._taskDb
        _maxRunning = settings._maxRunning
    }
}