//
//  C8oResponseXmlListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oResponseXmlListener: C8oResponseListener {
	public var onXmlResponse: (AnyObject?, Dictionary<String, AnyObject>?) -> ();
	
	public init(onXmlResponse: (AnyObject?, Dictionary<String, AnyObject>?) -> ()) {
		self.onXmlResponse = onXmlResponse
	}
}