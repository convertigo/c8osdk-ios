//
//  C8oPromise.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class C8oPromise<T>: C8oPromiseFailSync<T> {
	
	fileprivate var c8o: C8o
	fileprivate var c8oResponse: Pair < (T, Dictionary<String, AnyObject>) throws -> (C8oPromise<T>?), Bool >?
	fileprivate var c8oProgress: Pair < (C8oProgress) throws -> (), Bool >?
	fileprivate var c8oFail: Pair < (C8oException, Dictionary<String, AnyObject>?) throws -> (), Bool >?
	fileprivate var nextPromise: C8oPromise<T>?
	
	fileprivate var lastResponse: T?
	fileprivate var lastFailure: C8oException?
	fileprivate var lastParameters: Dictionary<String, AnyObject>?
	
	internal init(c8o: C8o) {
		self.c8o = c8o
	}
	
	open func then(_ c8oOnResponse: (_ response: T, _ parameters: Dictionary<String, AnyObject>) throws -> (C8oPromise<T>?), ui: Bool) -> C8oPromise<T> {
		if (nextPromise != nil) {
			return nextPromise!.then(c8oOnResponse, ui: ui)
		} else {
			c8oResponse = Pair < (T, Dictionary<String, AnyObject>) throws -> (C8oPromise<T>?), Bool > (key: c8oOnResponse, value: ui)
			nextPromise = C8oPromise<T>(c8o: c8o)
			if (lastFailure != nil) {
				nextPromise?.lastFailure = lastFailure
				nextPromise?.lastParameters = lastParameters
			}
			if (lastResponse != nil) {
				c8o.runBG({
					self.onResponse()
				})
			}
			return nextPromise!
		}
	}
	
	open func then(_ c8oOnResponse: (_ response: T, _ parameters: Dictionary<String, AnyObject>) throws -> (C8oPromise<T>?)) -> C8oPromise<T> {
		return then(c8oOnResponse, ui: false)
	}
	
	open func thenUI(_ c8oOnResponse: (_ response: T, _ parameters: Dictionary<String, AnyObject>) throws -> (C8oPromise<T>?)) -> C8oPromise<T> {
		return then(c8oOnResponse, ui: true)
	}
	
	open func progress(_ c8oOnProgress: (C8oProgress) throws -> (), ui: Bool) -> C8oPromiseFailSync<T> {
		if (nextPromise != nil) {
			return (nextPromise?.progress(c8oOnProgress, ui: ui))!
		} else {
			c8oProgress = Pair < (C8oProgress) throws -> (), Bool > (key: c8oOnProgress, value: ui)
			nextPromise = C8oPromise<T>(c8o: c8o)
			return nextPromise!
		}
	}
	
	open func progress(_ c8oOnProgress: (C8oProgress) throws -> ()) -> C8oPromiseFailSync<T> {
		return progress(c8oOnProgress, ui: false)
	}
	
	open func progressUI(_ c8oOnProgress: (C8oProgress) throws -> ()) -> C8oPromiseFailSync<T> {
		return progress(c8oOnProgress, ui: true)
	}
	
	open func fail(_ c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> (), ui: Bool) -> C8oPromiseSync<T> {
		if (nextPromise != nil) {
			return nextPromise!.fail(c8oOnFail, ui: ui)
		} else {
			c8oFail = Pair < (C8oException, Dictionary<String, AnyObject>?) throws -> (), Bool > (key: c8oOnFail, value: ui)
			nextPromise = C8oPromise<T>(c8o: c8o)
			if (lastFailure != nil) {
				c8o.runBG({
					self.onFailure(self.lastFailure!, parameters: self.lastParameters!)
				})
			}
			return nextPromise!
		}
	}
	
	open override func fail(_ c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> ()) -> C8oPromiseSync<T> {
		return fail(c8oOnFail, ui: false)
	}
	
	open override func failUI(_ c8oOnFail: (C8oException, Dictionary<String, AnyObject>?) throws -> ()) -> C8oPromiseSync<T> {
		return fail(c8oOnFail, ui: true)
	}
	
	open override func sync() throws -> T? {
		let thread = Thread.current
		var syncMutex: [Bool] = [Bool]()
		syncMutex.append(false)
		let condition: NSCondition = NSCondition()
		condition.lock()
		then { response, parameters in
			if (thread == Thread.current) {
				syncMutex[0] = true
				self.lastResponse = response
				
			} else {
				condition.lock()
				syncMutex[0] = true
				self.lastResponse = response
				condition.signal()
				condition.unlock()
			}
			return C8oPromise<T>?()
		}.fail { exception, parameters in
			if (thread == Thread.current) {
				syncMutex[0] = true
				self.lastFailure = exception
				
			} else {
				
				syncMutex[0] = true
				condition.lock()
				self.lastFailure = exception
				condition.signal()
				condition.unlock()
			}
			
		}
		if (!syncMutex[0]) {
			condition.wait()
		}
		
		condition.unlock()
		if (lastFailure != nil) {
			throw lastFailure!
		}
		return lastResponse
	}
	
	fileprivate func onResponse() -> Void {
		do {
			if (c8oResponse != nil) {
				var promise: [C8oPromise<T>?]? = [C8oPromise<T>]()
				if ((c8oResponse?.value)! as Bool) {
					var failure: C8oError? = nil
					let condition = NSCondition()
					condition.lock()
					let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
						
						condition.lock()
						do {
							promise?.append(try self.c8oResponse?.key(self.lastResponse!, self.lastParameters!))
						}
						catch let e as C8oError {
							failure = e
						}
						catch {
						}
						condition.signal()
						condition.unlock()
					}
					c8o.runUI(block)
					condition.wait()
					if (failure != nil) {
						throw failure!
					}
					condition.unlock()
				} else {
					do {
						promise?.append(try c8oResponse?.key(self.lastResponse!, self.lastParameters!))
					}
					
				}
				if (promise?.count > 0) {
					if (promise?[0] != nil) {
						if (nextPromise != nil) {
							var lastPromise = promise![0]
							while (lastPromise?.nextPromise != nil) {
								lastPromise = lastPromise!.nextPromise
							}
							lastPromise?.nextPromise = nextPromise
						}
						nextPromise = promise![0]
					} else if (nextPromise != nil) {
						nextPromise?.onResponse(lastResponse!, parameters: lastParameters!)
					}
				}
				
			} else if (nextPromise != nil) {
				nextPromise?.onResponse(lastResponse!, parameters: lastParameters!)
			} else {
				// Response received and no handler.
			}
			
		} catch let e as C8oException {
			onFailure(e, parameters: lastParameters!)
		} catch {
			
		}
	}
	
	internal func onResponse(_ response: T?, parameters: Dictionary<String, AnyObject>?) -> Void {
		if (lastResponse != nil && (parameters == nil || parameters![C8o.ENGINE_PARAMETER_FROM_LIVE] == nil)) {
			if (nextPromise != nil) {
				nextPromise?.onResponse(response, parameters: parameters)
			} else {
				c8o.log._trace("Another response received.", exceptions: nil)
			}
		} else {
			lastResponse = response
			lastParameters = parameters
			onResponse()
		}
	}
	
	internal func onProgress(_ progress: C8oProgress) -> Void {
		let condition: NSCondition = NSCondition()
		
		if (c8oProgress != nil) {
			if (c8oProgress!.value) {
				condition.lock()
				
				c8o.runUI {
					
					condition.lock()
					do {
						try self.c8oProgress?.key(progress)
						condition.signal()
					}
					catch let e as C8oException {
						self.onFailure(e, parameters: [C8o.ENGINE_PARAMETER_PROGRESS: progress])
						condition.signal()
					}
					catch {
						
					}
					
					condition.unlock()
				}
				condition.wait()
				condition.unlock()
				
			} else {
				try! c8oProgress?.key(progress)
			}
		} else if (nextPromise != nil) {
			nextPromise?.onProgress(progress)
		}
	}
	
	internal func onFailure(_ exception: C8oException?, parameters: Dictionary<String, AnyObject>?) -> Void {
		lastFailure = exception
		lastParameters = parameters
		
		if (c8oFail != nil) {
			if (c8oFail!.value) {
				let condition: NSCondition = NSCondition()
				condition.lock()
				
				c8o.runUI {
					
					condition.lock()
					
					do {
						try self.c8oFail?.key(exception!, parameters)
					}
					catch let e as C8oException {
						self.lastFailure = e
						condition.signal()
					}
					catch {
						
					}
					condition.signal()
					condition.unlock()
				}
				condition.wait()
				condition.unlock()
			} else {
				try! self.c8oFail?.key(lastFailure!, parameters)
			}
		}
		if (nextPromise != nil) {
			nextPromise?.onFailure(lastFailure!, parameters: parameters)
		}
		
	}
}
