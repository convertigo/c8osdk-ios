//
//  C8oResponseJsonListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

open class C8oResponseJsonListener: C8oResponseListener {
	open var onJsonResponse: (JSON?, Dictionary<String, Any>?) -> ()
	
	public init(onJsonResponse: @escaping (JSON?, Dictionary<String, Any>?) -> ()) {
		self.onJsonResponse = onJsonResponse
	}
}
