//
//  C8oFullSyncChangeListener.swift
//  C8oSDKiOS
//
//  Created by Nicolas Albert on 08/11/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

public class C8oFullSyncChangeListener : Hashable {
    private static var c = 0
    private let i = c
    
    let handler: (changes: JSON) -> ()
    
    public init(handler: (changes: JSON) -> ()) {
        C8oFullSyncChangeListener.c = C8oFullSyncChangeListener.c + 1
        self.handler = handler
    }
    
    public var hashValue: Int {
        get {
            return i
        }
    }
}

public func ==(lhs: C8oFullSyncChangeListener, rhs: C8oFullSyncChangeListener) -> Bool {
    return lhs.hashValue == rhs.hashValue
}