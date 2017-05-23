//
//  C8oResponseXmlListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oResponseXmlListener: C8oResponseListener {
	open var onXmlResponse: (Any?, Dictionary<String, Any>?) -> ();
	
	public init(onXmlResponse: @escaping (Any?, Dictionary<String, Any>?) -> ()) {
		self.onXmlResponse = onXmlResponse
	}
}
