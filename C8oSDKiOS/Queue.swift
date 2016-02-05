//
//  Queue.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 05/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

class QNode<T>
{
    var key: T?
    var next: QNode?
}

public class Queue<T>
{
    private var top: QNode<T>! = QNode<T>()
    //enqueue the specified object
    func enQueue(var key: T) {
        //check for the instance
        if (top == nil)
        {
            top = QNode<T>()
        }
        //establish the top node
        if (top.key == nil)
        {
            top.key = key;
            return
        }
        var childToUse: QNode<T> = QNode<T>()
        var current: QNode = top
        
        //cycle through the list of items to get to the end.
        while (current.next != nil)
        {
            current = current.next!
        }
        
        //append a new item 
        childToUse.key = key;
        current.next = childToUse;
    }
        
}