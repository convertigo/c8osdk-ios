//
//  C8oLocalCacheResponse.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 07/04/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

class C8oLocalCacheResponse {
	
	private var response: String
	private var responseType: String
	private var expirationDate: Double
	
	internal init(response: String, responseType: String, expirationDate: Double) {
		self.response = response
		self.responseType = responseType
		self.expirationDate = expirationDate
	}
	
	internal func isExpired() -> Bool {
		if (expirationDate <= 0) {
			return false
		} else {
			let currentDate = NSDate().timeIntervalSince1970 * 1000
			return Double(expirationDate) < currentDate
		}
	}
	internal func getResponse() -> String {
		return response
	}
	
	internal func getResponseType() -> String {
		return responseType
	}
	
	internal func getExpirationDate() -> Double {
		return expirationDate
	}
	
}