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
    public func clone()->C8oFileTransferSettings{
        return C8oFileTransferSettings(c8oFileTransferSettings: self)
    }
    public func setMaxRunning(maxRunning:Int)throws ->C8oFileTransferSettings{
        if(maxRunning <= 0 || maxRunning > 4){
            throw C8oException(message: "maxRunning must be between 1 and 4")
        }
        else{
            self.maxRunning = maxRunning
        }
        return self
    }
}