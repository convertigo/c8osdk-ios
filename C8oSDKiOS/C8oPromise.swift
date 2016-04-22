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


public class C8oPromise<T> : C8oPromiseFailSync<T>
{
    
    private var c8o : C8o
    private var c8oResponse : Pair<(T, Dictionary<String, AnyObject>)throws ->(C8oPromise<T>?), Bool>?
    private var c8oProgress : Pair<(C8oProgress)throws ->(),Bool>?
    private var c8oFail : Pair<(C8oException, Dictionary<String, AnyObject>?)throws ->(),Bool>?
    private var nextPromise : C8oPromise<T>?
    
    private var lastResponse : T?
    private var lastFailure : C8oException?
    private var lastParameters : Dictionary<String, AnyObject>?
    
    internal init(c8o : C8o)
    {
        self.c8o = c8o
    }
    
    
    public func then(c8oOnResponse : (response : T, parameters : Dictionary<String, AnyObject>)throws->(C8oPromise<T>?), ui : Bool)-> C8oPromise<T>?
    {
        if(nextPromise != nil){
            return nextPromise!.then(c8oOnResponse, ui: ui)
        }
        else{
            c8oResponse = Pair<(T, Dictionary<String, AnyObject>) throws ->(C8oPromise<T>?), Bool>(key: c8oOnResponse, value: ui)
            nextPromise = C8oPromise<T>(c8o: c8o)
            if(lastFailure != nil){
                nextPromise?.lastFailure = lastFailure
                nextPromise?.lastParameters = lastParameters
            }
            if(lastResponse != nil){
                onResponse()
            }
            return nextPromise
        }
    }
    
    public func then(c8oOnResponse : (response : T, parameters : Dictionary<String, AnyObject>)throws->(C8oPromise<T>?))-> C8oPromise<T>?{
        return then(c8oOnResponse, ui: false)
    }
    
    public func thenUI(c8oOnResponse : (response : T, parameters : Dictionary<String, AnyObject>)throws->(C8oPromise<T>?))-> C8oPromise<T>?{
        return then(c8oOnResponse, ui: true)
    }
    
    
    public func progress(c8oOnProgress : (C8oProgress)throws ->(), ui : Bool)->C8oPromiseFailSync<T>
    {
        if(nextPromise != nil){
            return (nextPromise?.progress(c8oOnProgress, ui: ui))!
        }
        else{
            c8oProgress = Pair<(C8oProgress)throws ->(), Bool>(key: c8oOnProgress, value: ui)
            nextPromise = C8oPromise<T>(c8o: c8o)
            return nextPromise!
        }
    }
    
    public func progress(c8oOnProgress : (C8oProgress)throws ->())->C8oPromiseFailSync<T>
    {
        return progress(c8oOnProgress, ui: false)
    }
    
    
    public func progressUI(c8oOnProgress : (C8oProgress)throws ->())->C8oPromiseFailSync<T>
    {
        return progress(c8oOnProgress, ui: true)
    }
    
    public func fail(c8oOnFail : (C8oException, Dictionary<String, AnyObject>?)throws ->(), ui : Bool)->C8oPromiseSync<T>
    {
        if (nextPromise != nil) {
            return nextPromise!.fail(c8oOnFail, ui: ui)
        } else {
            c8oFail = Pair<(C8oException, Dictionary<String, AnyObject>?)throws ->(), Bool>(key: c8oOnFail, value: ui)
            nextPromise = C8oPromise<T>(c8o: c8o)
            if (lastFailure !=  nil) {
                onFailure(lastFailure!, parameters: lastParameters!)
            }
            return nextPromise!
        }
    }
    
    public func fail(c8oOnFail : (C8oException, Dictionary<String, AnyObject>?)throws ->())->C8oPromiseSync<T>
    {
        return fail(c8oOnFail, ui: false)
    }
    
    
    public func failUI(c8oOnFail : (C8oException, Dictionary<String, AnyObject>?)throws ->())->C8oPromiseSync<T>
    {
        return fail(c8oOnFail, ui: true)
    }
    
    
    public override func sync() throws -> T?
    {
        let thread = NSThread.currentThread()
        var syncMutex : [Bool] = [Bool]()
        syncMutex.append(false)
        let condition : NSCondition = NSCondition()
        condition.lock()
        then { response , parameters in
            if(thread == NSThread.currentThread()){
                syncMutex[0] = true
                self.lastResponse = response
                
            }
            else{
                condition.lock()
                syncMutex[0] = true
                self.lastResponse = response
                condition.signal()
                condition.unlock()
            }
            return nil as C8oPromise<T>?
            }?.fail { exception , parameters in
                if(thread == NSThread.currentThread()){
                    syncMutex[0] = true
                    self.lastFailure = exception
                    
                }
                else{
                    
                    syncMutex[0] = true
                    condition.lock()
                    self.lastFailure = exception
                    condition.signal()
                    condition.unlock()
                }
                
        }
        if(!syncMutex[0]){
            condition.wait()
        }
        
        condition.unlock()
        if(lastFailure != nil){
            throw lastFailure!
        }
        return lastResponse
    }
    
    private func onResponse()->Void{
        do{
            if(c8oResponse != nil){
                var promise : [C8oPromise<T>?]? = [C8oPromise<T>]()
                if((c8oResponse?.value)! as Bool){
                    var failure : C8oError? = nil
                    let condition = NSCondition()
                    condition.lock()
                    let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
                        
                        condition.lock()
                        do{
                            promise?.append(try self.c8oResponse?.key(self.lastResponse!, self.lastParameters!))
                        }
                        catch let e as C8oError{
                            failure = e
                        }
                        catch _ as NSException{
                            print("exception....")
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
                            while(lastPromise?.nextPromise != nil) {
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
    
    internal func onResponse(response :T, parameters : Dictionary<String, AnyObject>)->Void{
        if(lastResponse != nil){
            if(nextPromise != nil){
                nextPromise?.onResponse(response, parameters: parameters)
            }
            else{
                c8o.log._trace("Another response received.", exceptions: nil)
            }
        }
        else{
            lastResponse = response
            lastParameters = parameters
            onResponse()
        }
    }
    
    internal func onProgress(progress : C8oProgress) ->Void
    {
        let condition : NSCondition = NSCondition()
        
        if (c8oProgress != nil)
        {
            if (c8oProgress!.value)
            {
                condition.lock()
                
                c8o.runUI {
                    
                    condition.lock()
                    do
                    {
                        try! self.c8oProgress?.key(progress)
                        condition.signal()
                    }
                    /*catch let e as C8oException
                    {
                        self.onFailure(e, parameters: [C8o.ENGINE_PARAMETER_PROGRESS : progress ])
                        condition.signal()
                    }*/
                    
                    condition.unlock()
                }
                condition.wait()
                condition.unlock()
                
            }
            else
            {
                try! c8oProgress?.key(progress)
            }
        }
        else if(nextPromise != nil){
            nextPromise?.onProgress(progress)
        }
    }
    
    
    
    internal func onFailure(exception : C8oException?, parameters : Dictionary<String, AnyObject>?)-> Void
    {
        lastFailure = exception
        lastParameters = parameters
        
        if (c8oFail != nil)
        {
            if (c8oFail!.value)
            {
                let condition : NSCondition = NSCondition()
                condition.lock()
                
                c8o.runUI {
                    
                    condition.lock()
                    
                    do
                    {
                        try! self.c8oFail?.key(exception!, parameters!)
                    }
                    /*catch let e as C8oException
                    {
                        self.lastFailure = e
                        condition.signal()
                    }*/
                    condition.signal()
                    condition.unlock()
                }
                condition.wait()
                condition.unlock()
            }
            else
            {
                try! self.c8oFail?.key(lastFailure!, parameters)
            }
        }
        if(nextPromise != nil){
            nextPromise?.onFailure(lastFailure!, parameters: parameters)
        }
        
    }
}
