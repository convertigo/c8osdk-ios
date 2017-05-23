//
//  C8oExceptionListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oExceptionListener {
	open var onException: (Pair<C8oException, Dictionary<String, Any>?>?) -> ()
	
	init(onException: @escaping (_ params: Pair<C8oException, Dictionary<String, Any>?>?) -> ()) {
		self.onException = onException;
	}
}
