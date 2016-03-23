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
    private var c8oResponse : Pair<(T, Dictionary<String, NSObject>)throws ->(C8oPromise<T>?), Bool>?
    private var c8oProgress : Pair<(C8oProgress)throws ->(),Bool>?
    private var c8oFail : Pair<(C8oException, Dictionary<String, NSObject>)throws ->(),Bool>?
    private var nextPromise : C8oPromise<T>?
    
    private var lastResponse : T?
    private var lastFailure : C8oException?
    private var lastParameters : Dictionary<String, NSObject>?
    
    internal init(c8o : C8o)
    {
        self.c8o = c8o
        //super.init()
        
    }
    
    
    public func Then(c8oOnResponse : (response : T, parameters : Dictionary<String, NSObject>)->(C8oPromise<T>?), ui : Bool)-> C8oPromise<T>?
    {
        if(nextPromise != nil){
            return nextPromise!.Then(c8oOnResponse, ui: ui)
        }
        else{
            c8oResponse = Pair<(T, Dictionary<String, NSObject>) throws ->(C8oPromise<T>?), Bool>(key: c8oOnResponse, value: ui)
            nextPromise = C8oPromise<T>(c8o: c8o)
            if(lastFailure != nil){
                nextPromise?.lastFailure = lastFailure
                nextPromise?.lastParameters = lastParameters
            }
            if(lastResponse != nil){
                OnResponse()
            }
            return nextPromise
        }
    }
    
    public func Then(c8oOnResponse : (response : T, parameters : Dictionary<String, NSObject>)->(C8oPromise<T>?))-> C8oPromise<T>?{
        return Then(c8oOnResponse, ui: false)
    }
    
    public func ThenUI(c8oOnResponse : (response : T, parameters : Dictionary<String, NSObject>)->(C8oPromise<T>?))-> C8oPromise<T>?{
        return Then(c8oOnResponse, ui: true)
    }
    
    
    public func Progress(c8oOnProgress : (C8oProgress)throws ->(), ui : Bool)->C8oPromiseFailSync<T>
    {
        if(nextPromise != nil){
            return (nextPromise?.Progress(c8oOnProgress, ui: ui))!
        }
        else{
            c8oProgress = Pair<(C8oProgress)throws ->(), Bool>(key: c8oOnProgress, value: ui)
            nextPromise = C8oPromise<T>(c8o: c8o)
            return nextPromise!
        }
    }
    
    public func Progress(c8oOnProgress : (C8oProgress)throws ->())->C8oPromiseFailSync<T>
    {
        return Progress(c8oOnProgress, ui: false)
    }

    
    public func ProgressUI(c8oOnProgress : (C8oProgress)throws ->())->C8oPromiseFailSync<T>
    {
        return Progress(c8oOnProgress, ui: true)
    }
    
    public func Fail(c8oOnFail : (C8oException, Dictionary<String, NSObject>)throws ->(), ui : Bool)->C8oPromiseSync<T>
    {
        if(nextPromise != nil){
            return nextPromise!.Fail(c8oOnFail, ui: ui)
        }
        else{
            c8oFail = Pair<(C8oException, Dictionary<String, NSObject>)throws ->(), Bool>(key: c8oOnFail, value: ui)
            nextPromise = C8oPromise<T>(c8o: c8o)
            if(lastFailure !=  nil){
                OnFailure(lastFailure!, parameters: lastParameters!)
            }
            return nextPromise!
        }
    }
    
    public func Fail(c8oOnFail : (C8oException, Dictionary<String, NSObject>)throws ->())->C8oPromiseSync<T>
    {
        return Fail(c8oOnFail, ui: false)
    }
    
    
    public func FailUI(c8oOnFail : (C8oException, Dictionary<String, NSObject>)throws ->())->C8oPromiseSync<T>
    {
        return Fail(c8oOnFail, ui: true)
    }
    
    
    public func Sync() throws -> T?
    {
        let thread = NSThread.currentThread()
        var syncMutex : [Bool] = [Bool]()
        syncMutex.append(false)
        let condition : NSCondition = NSCondition()
        condition.lock()
            self.Then { response , parameters in
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
                }?.Fail { exception , parameters in
                    if(thread == NSThread.currentThread()){
                        syncMutex[0] = true
                        self.lastFailure = exception

                    }
                    else{
                        condition.lock()
                        syncMutex[0] = true
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
    
    private func OnResponse()->Void{
        do{
            if(c8oResponse != nil){
                var promise : [C8oPromise<T>?]? = [C8oPromise<T>]()
                if((c8oResponse?.value)! as Bool){
                    var failure : C8oError? = nil
                    let condition = NSCondition()
                    condition.lock()
                    c8o.RunUI {block in
                        condition.lock()
                            do{
                                promise!.append(try! self.c8oResponse!.key(self.lastResponse!, self.lastParameters!)!)
                            }
                            catch let e as C8oError{
                                failure = e
                            }
                            catch let e as NSException{
                                print("exception....")
                            }
                            condition.signal()
                        condition.unlock()
                    }
                    condition.wait()
                    if(failure != nil){
                        throw failure!
                    }
                    condition.unlock()
                }
                else{
                    promise!.append(try! c8oResponse!.key(lastResponse!, lastParameters!))
                }
                if(promise![0] != nil){
                    if(nextPromise != nil){
                        var lastPromise = promise![0]
                        while(lastPromise != nil)
                        {
                            lastPromise = lastPromise!.nextPromise
                        }
                        lastPromise?.nextPromise = nextPromise
                    }
                    nextPromise = promise![0]
                }
                else if (nextPromise != nil){
                    nextPromise?.OnResponse(lastResponse!, parameters: lastParameters!)
                }
            }
            else if (nextPromise != nil){
                nextPromise?.OnResponse(lastResponse!, parameters: lastParameters!)
            }
            else{
                 // Response received and no handler.
            }
            
        }
        catch let e as C8oException{
            OnFailure(e, parameters: lastParameters!)
        }
        catch{
            
        }
    }
    
    internal func OnResponse(response :T, parameters : Dictionary<String, NSObject>)->Void{
        if(lastResponse != nil){
            if(nextPromise != nil){
                nextPromise?.OnResponse(response, parameters: parameters)
            }
            else{
                c8o.Log._Trace("Another response received.", exceptions: nil)
            }
        }
        else{
            lastResponse = response
            lastParameters = parameters
            OnResponse()
        }
    }
    
    internal func OnProgress(progress : C8oProgress) ->Void
    {
        let condition : NSCondition = NSCondition()
        
        if (c8oProgress != nil)
        {
            if (c8oProgress!.value)
            {
                condition.lock()
                
                c8o.RunUI {
                    
                    condition.lock()
                    do
                    {
                        try! self.c8oProgress?.key(progress)
                        condition.signal()
                    }
                    catch let e as C8oException
                    {
                        self.OnFailure(e, parameters: [C8o.ENGINE_PARAMETER_PROGRESS : progress ])
                        condition.signal()
                    }
                    
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
            nextPromise?.OnProgress(progress)
        }
    }
    
    
    
    internal func OnFailure(exception : C8oException, parameters : Dictionary<String, NSObject>)-> Void
    {
        lastFailure = exception
        lastParameters = parameters
        
        if (c8oFail != nil)
        {
            if (c8oFail!.value)
            {
                let condition : NSCondition = NSCondition()
                condition.lock()
                
                c8o.RunUI {
                    
                    condition.lock()
                    
                    do
                    {
                        try! self.c8oFail?.key(exception, parameters)
                    }
                    catch let e as C8oException
                    {
                        self.lastFailure = e
                        condition.signal()
                    }
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
            nextPromise?.OnFailure(lastFailure!, parameters: parameters)
        }
        
    }
}
