//
//  C8oFullSyncChangeListener.swift
//  C8oSDKiOS
//
//  Created by Nicolas Albert on 08/11/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

@objc open class C8oFullSyncChangeListener : NSObject {
    fileprivate static var c = 0
    fileprivate let i = c
    
    @objc let handler: (_ changes: NSDictionary) -> ()
    
    @objc public init(handler: @escaping (_ changes: NSDictionary) -> ()) {
        C8oFullSyncChangeListener.c = C8oFullSyncChangeListener.c + 1
        self.handler = handler
    }
    
}

