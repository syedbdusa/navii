//
//  Logging.swift
//  Navii
//
//  Created by Jason Wang on 5/6/19.
//  Copyright © 2019 Navii. All rights reserved.
//

import Foundation
class LogDestination: TextOutputStream {
    var path: URL
    init(url saveURL: URL) {
        path = saveURL
    }
    
    func write(_ string: String) {
        do {
            if let data = string.data(using: .utf8){
                let fileHandle = try FileHandle(forWritingTo: path)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } catch {
            fatalError("saving debug INFO to \(path) went wrong")
        }
    }
}

