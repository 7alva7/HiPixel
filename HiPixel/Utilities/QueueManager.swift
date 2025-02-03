//
//  QueueManager.swift
//  HiPixel
//
//  Created by 十里 on 2024/10/31.
//

import Foundation

class QueueManager {

    var maxConcurrentOperationCount: Double = 4
    
    static let shared = QueueManager(num: 2)
    
    var queues = [OperationQueue]()
    var counts = [Int]()
    
    let num: Int
    
    var index = 1
    
    init(num: Int) {
        self.num = num
        for _ in 1...num {
            let queue = OperationQueue()
            queue.qualityOfService = .userInitiated
            queue.maxConcurrentOperationCount = Int(maxConcurrentOperationCount)
            queues.append(queue)
            counts.append(0)
        }
    }
    
    func allocate(count: Int) -> OperationQueue {
        if let minCount = counts.min(), let indexOfminValue = counts.firstIndex(of: minCount) {
            index = indexOfminValue
        } else {
            index += 1
            if index >= num {
                index = 0
            }
        }
        counts[index] += count
        return queues[index]
    }
}
