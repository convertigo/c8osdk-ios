//
//  C8oFullSyncCbl.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 23/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CouchbaseLite

internal class C8oFullSyncCbl : C8oFullSync{
    private var fullSyncDatabases : Dictionary<String, C8oFullSyncDatabase>?;
    private var manager : CBLManager?;
    
    internal init(c8o: C8o) {
        super.init()
        self.fullSyncDatabases = Dictionary<String, C8oFullSyncDatabase>();
        self.manager = CBLManager()
        
    }
    
    
    
}