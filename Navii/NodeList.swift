//
//  NodeList.swift
//  Navii
//
//  Created by Jason Wang on 5/6/19.
//  Copyright © 2019 Navii. All rights reserved.
//

import Foundation

struct Node: Comparable {
    // structure definition goes here
    var value: Int
    var distance: Double
    
    var back: Int
    static func < (left: Node, right: Node) -> Bool {
        return left.distance < right.distance
    }
    static func == (left: Node, right: Node) -> Bool {
        return left.distance == right.distance
    }
}
struct NodeList {
    var fringe : [Node]
    mutating func add(newNode: Node) {
        let index = findIndex(newNode: newNode)
        fringe.insert(newNode, at: index)
    }
    mutating func pop() -> Node{
        return fringe.remove(at: 0)
    }
    func count() -> Int{
        return fringe.count
    }
    func findIndex(newNode: Node) -> Int{
        if(fringe.count == 0) {
            return 0
        }
        var low = 0
        var high = fringe.count - 1
        while(low <= high) {
            let mid = (low + high) / 2
            if(fringe[mid] < newNode) {
                low = mid + 1
            } else if(newNode < fringe[mid]) {
                high = mid - 1
            } else {
                return mid
            }
        }
        return low
    }
}
