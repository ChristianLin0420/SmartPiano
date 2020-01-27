//
//  ChordsAnalyse.swift
//  Digital_flute
//
//  Created by Christian Lin on 2019/2/6.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import Foundation

class ChordsAnalyse {
    
    var identities = [[2,14], //#G
                      [4,16], //#A
                      [7],    //#C
                      [9],    //#D
                      [12]]   //#F

    let chords_array = ["G","D","A","E","B","C","F","Bb","Eb","Ab","a","d","g","c","f","e","b"]
    let chords_identities = [[0,0,0,0,1],[0,0,1,0,1],[1,0,1,0,1],[1,0,1,1,1],[1,1,1,1,1],
                             [0,0,0,0,0],[0,1,0,0,0],[0,1,0,1,0],[1,1,0,1,0],[1,1,1,1,0],
                             [1,0,0,0,0],[0,1,1,0,0],[0,1,0,1,1],[1,0,0,1,0],[1,1,1,0,0],
                             [0,0,0,1,0],[0,1,1,0,1]]
    
    func match(array: [[Int]]) -> String {
        var isMatch = [Int](repeatElement(0, count: 5)) //record wether particular note in the identities
        var chord_result = ""
        
        //first: find the max up or down
        for i in 0...array.count - 1 {
            if array[i][0] != 99 && array[i][0] < 20 {
                for j in 0...4 {
                    for k in 0...4 {
                        for m in 0...identities[k].count - 1 {
                            if isMatch[k] == 1 {
                                print("break")
                                break
                            } else if array[i][j] == identities[k][m] && isMatch[k] == 0 {
                                print(array[i])
                                print("-->\(k)")
                                isMatch[k] = 1
                            }
                        }
                    }
                }
            }
        }
        print(isMatch)
        
        //second:return the result of the chord
        for i in 0...chords_identities.count - 1 {
            if isMatch == chords_identities[i] {
                chord_result = chords_array[i]
            }
        }
                
        //third: return the chord of the song
        return chord_result
    }
}
