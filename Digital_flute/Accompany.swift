//
//  Accompany.swift
//  Digital_flute
//
//  Created by Christian Lin on 2019/2/19.
//  Copyright © 2019 Christian Lin. All rights reserved.

import Foundation
import CoreData
import UIKit

class Accompany: UIViewController {
    
    //replay
    var replay_signal = false
    var replay_current_count = 0
    var tap_change = 1
    
    var CoreDataVC = CoreDataManage()
    var SongListVC = SongsListViewController()
    var song_number = -1
    
    var time = Timer()
    var sec = 0.0
    
    var PianoDefaults = UserDefaults.standard
    var first_10_notes_array = [[[Int]]]()
    
    func convert_target_array_to_time_duration_array(target_array: [[Int]]) -> [[Int]] {
        var result_array = [[Int]]()
        //var zero_array_index = 0
        let zero = [0,0,0,0,0]
        var note_amount = 0
        
        if target_array.count > 0 {
            for i in 0...target_array.count - 1 {
                if target_array[i] != zero && note_amount < 10 {
                    var flag = 1
                    for j in 0...4 {
                        if target_array[i][j] > 20 {
                            flag = 0
                            break
                        }
                    }
                    if flag == 1 {
                        result_array.append(target_array[i])
                        note_amount += 1
                    }
                } else if note_amount == 10 || i == target_array.count - 1 {
                    break
                }
            }
        }
        
        return result_array
    }
    
    func comparison(temp_array: [[Int]], temp_array_count: Int) -> (Int, Int, Int) {
        CoreDataVC.getData()
        
        if let buffer = PianoDefaults.object(forKey: "first_10") {
            first_10_notes_array = buffer as! [[[Int]]]
        } else {
            first_10_notes_array = [[[0]]]
        }
        
        
        var target_array = convert_target_array_to_time_duration_array(target_array: temp_array)
        
        if CoreDataVC.first_10_notes.count > 0 {
            if first_10_notes_array.count > 0 {
                for index in 0...first_10_notes_array.count - 1 {
                    let melody_array = first_10_notes_array[index] // be compared array
                    let target_array_count = target_array.count
                    let melody_array_count = melody_array.count
                    var target_array_current_notes_amount = 0
                    
                    //print("melody_acount = \(melody_array_count)")
                    //print("melody_array = \(melody_array)")
                    //print("target_count = \(target_array_count)")
                    //print("target_array = \(target_array)")
                    
                    if target_array_count > 4 { //&& melody_array_count > 7 {
                        if CoreDataVC.first_10_notes.count == 0 {
                            return (-1, target_array.count, 0)
                        } else {
                            var time_for_return = false
                            
                            if target_array_count <= melody_array_count && target_array_count > 5  {
                                var matching_number = 0
                                target_array_current_notes_amount += 1
                                for j in 0...4 {
                                    if melody_array[j].count > 1 {
                                        var matching_value = true
                                        for k in 0...4 {
                                            for m in 0...4 {
                                                if melody_array[j][k] == target_array[j][m] { break }
                                                else if melody_array[j][k] != target_array[j][m] && m == 4 { matching_value = false }
                                            }
                                        }
                                        if matching_value == true { matching_number += 1 }
                                    } else if melody_array[j].count == 1 {
                                        target_array_current_notes_amount += melody_array[j][0]
                                    }
                                }
                                
                                let similar_value = similar(numb: 5, matching_amount: matching_number)
                                
                                if similar_value == true  { //}&& target_array_count != temp_array_count {
                                    time_for_return = false
                                    
                                    print("target_array = \(target_array.count)")
                                    
                                    return (index, target_array.count, target_array_current_notes_amount)
                                }
                                
                                if index == first_10_notes_array.count - 1 && similar_value == false {
                                    return (-3, target_array.count, 0)
                                }
                                
                            } else if target_array_count < melody_array_count && target_array_count <= 5 {
                                return (-2, target_array.count, 0)
                            } else if target_array_count > melody_array_count {
                                
                                var matching_number = 0
                                target_array_current_notes_amount += 1
                                for j in 0...melody_array_count - 1 {
                                    if melody_array[j].count > 1 {
                                        var matching_value = true
                                        for k in 0...4 {
                                            for m in 0...4 {
                                                if melody_array[j][k] == target_array[j][m] { break }
                                                else if melody_array[j][k] != target_array[j][m] && m == 4 { matching_value = false }
                                            }
                                        }
                                        if matching_value == true { matching_number += 1 }
                                    } else if melody_array[j].count == 1 {
                                        target_array_current_notes_amount += melody_array[j][0]
                                    }
                                }
                                
                                let similar_value = similar(numb: melody_array_count, matching_amount: matching_number)
                                
                                if index == first_10_notes_array.count - 1 && similar_value == false {
                                    return (-3, target_array.count, 0)
                                } else if index == first_10_notes_array.count - 1 && similar_value == true {
                                    return (-2, target_array.count, 0)
                                }
                            }
                            
                            if index == first_10_notes_array.count - 1 {
                                if time_for_return == true { return (-3, target_array.count, 0) }
                            }
                        }
                    }
                }

            }
        }
        return (-2, target_array.count, 0)
    }
    
    func similar(numb: Int, matching_amount: Int) -> Bool {
        //print("numb = \(numb), matching_amount = \(matching_amount)")
        if Double(matching_amount) / Double(numb) < 0.8 { return false }
        return true
    }
    
    func runTimer() {
        time = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in self.updateTimer()}
    }
    
    func updateTimer() {
        sec += 1
    }
}
