//
//  C8oFileTransferBase.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 13/07/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oFileTransferBase{
    internal var maxRunning : Int = 4
    
    public func getMaxRunning()->Int{
        return maxRunning
    }
    public func copy(c8oFileTransferSettings : C8oFileTransferSettings){
        maxRunning = c8oFileTransferSettings.getMaxRunning()
    }
}