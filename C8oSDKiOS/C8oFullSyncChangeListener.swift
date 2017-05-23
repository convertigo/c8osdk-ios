//
//  C8oFullSyncChangeListener.swift
//  C8oSDKiOS
//
//  Created by Nicolas Albert on 08/11/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

open class C8oFullSyncChangeListener : Hashable {
    fileprivate static var c = 0
    fileprivate let i = c
    
    let handler: (_ changes: JSON) -> ()
    
    public init(handler: (_ changes: JSON) -> ()) {
        C8oFullSyncChangeListener.c = C8oFullSyncChangeListener.c + 1
        self.handler = handler
    }
    
    open var hashValue: Int {
        get {
            return i
        }
    }
}

public func ==(lhs: C8oFullSyncChangeListener, rhs: C8oFullSyncChangeListener) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
