//
//  CoreDataManage.swift
//  Digital_flute
//
//  Created by Christian Lin on 2019/2/19.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class CoreDataManage {
    
    //songs
    var songs: [NSManagedObject] = []
    var first_10_notes: [NSManagedObject] = []
    var songs_melody: [NSManagedObject] = []
    var songs_notes: [NSManagedObject] = []
    
    //row number -> record song list number
    var row = 0
    
    //getting data instantly
    func getData() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest_1 = NSFetchRequest<NSManagedObject>(entityName: "Songs")
        let fetchRequest_2 = NSFetchRequest<NSManagedObject>(entityName: "Melody")
        let fetchRequest_3 = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let fetchRequest_4 = NSFetchRequest<NSManagedObject>(entityName: "First_10")
        
        do {
            songs = try managedContext.fetch(fetchRequest_1)
            songs_melody = try managedContext.fetch(fetchRequest_2)
            songs_notes = try managedContext.fetch(fetchRequest_3)
            first_10_notes = try managedContext.fetch(fetchRequest_4)
        } catch {
            print(error)
        }
    }
    
    func detect_song(temp_array: [[Int]]) -> Bool {
        getData()
        
        var matching_amount = 0
        let data_count = songs.count
        
        if data_count == 0 {
            return true
        } else {
            for i in 0...data_count - 1 {
                var target_array = read_and_make_compare_notes(index: i)
                var detect_length = 0
                
                if temp_array.count >= target_array.count { detect_length = target_array.count }
                else { detect_length = temp_array.count }
                
                for j in 0...detect_length - 1 {
                    var matching_value = true
                    for k in 0...4 {
                        for m in 0...4 {
                            if temp_array[j][k] == target_array[j][m] { break }
                            else if temp_array[j][k] != target_array[j][m] && m == 4 { matching_value = false }
                        }
                    }
                    if matching_value == true { matching_amount += 1 }
                }
                
                if similar(numb: detect_length, matching_amount: matching_amount) == true {
                    row = i
                    return false
                }
            }
        }
        return true
    }
    
    func similar(numb: Int, matching_amount: Int) -> Bool{
        //caculating the similar rate
        if Double(matching_amount) / Double(numb) < 0.75 { return false }
        return true
    }
    
    func read_and_make_compare_notes (index: Int) -> [[Int]] {
        getData()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Melody")
        var melody_string = [String]()
        var melody_int  = [[Int]]()
        var melody_int_buffer = [Int]()
        var melody_result = [[Int]]()
        
        do {
            var result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            let melody = result[index].value(forKey: "melody") as! String
            
            if (melody.count > 0) {
                var data: String = ""
                for i in 0...(melody.count / 10 - 1) {
                    let lowerBound = melody.index(melody.startIndex, offsetBy: i * 10)
                    let upperBound = melody.index(melody.startIndex, offsetBy: i * 10 + 10)
                    data = String(melody[lowerBound..<upperBound])
                    melody_string.append(data)
                }
            }
            
            for i in 0...melody_string.count - 1 {
                var data: String = ""
                for j in 0...melody_string[i].count / 2 - 1 {
                    let lowerBound = melody_string[i].index(melody_string[i].startIndex, offsetBy: j * 2)
                    let upperBound = melody_string[i].index(melody_string[i].startIndex, offsetBy: j * 2 + 2)
                    data = String(melody_string[i][lowerBound..<upperBound])
                    melody_int_buffer.append(Int(data)!)
                }
                melody_int.append(melody_int_buffer)
                melody_int_buffer.removeAll()
            }
            
            for i in 0...melody_int.count - 1 {
                if melody_int[i][0] != 99 {
                    melody_result.append(melody_int[i])
                }
            }
            
        } catch {
            print("failed to get melody!!!")
        }
        
        return melody_result
    }
}
