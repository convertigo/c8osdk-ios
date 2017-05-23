//
//  C8oPromiseFailSync.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

open class C8oPromiseFailSync<T>: C8oPromiseSync<T> {    
    open func fail(_ c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> ()) -> C8oPromiseSync<T> {
        return self
    }
    open func failUI(_ c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> ()) -> C8oPromiseSync<T> {
        return self
    }
}
