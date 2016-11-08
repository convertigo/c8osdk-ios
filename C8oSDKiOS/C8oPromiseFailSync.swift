//
//  C8oPromiseFailSync.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

public class C8oPromiseFailSync<T>: C8oPromiseSync<T> {    
    public func fail(c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> ()) -> C8oPromiseSync<T> {
        return self
    }
    public func failUI(c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> ()) -> C8oPromiseSync<T> {
        return self
    }
}