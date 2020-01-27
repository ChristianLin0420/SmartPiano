
//
//  ViewController.swift
//  Digital_flute
//
//  Created by Christian Lin on 2019/03/12
//  Copyright © 2018 Christian Lin. All rights reserved.

import UIKit
import AVFoundation
import CoreData

class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    let references_upper = ["Piano.G3", "Piano.Ab3","Piano.A3", "Piano.Bb3","Piano.B3", "Piano.C4", "Piano.Db4","Piano.D4", "Piano.Eb4", "Piano.E4", "Piano.F4", "Piano.Gb4", "Piano.G4", "Piano.Ab4", "Piano.A4", "Piano.Bb4", "Piano.B4"]
    let references_lower = ["Piano.G3", "Piano.A3", "Piano.B3", "Piano.C4", "Piano.D4", "Piano.E4", "Piano.F4", "Piano.G4", "Piano.A4", "Piano.B4"]
    let list_image = ["list0", "list1", "list2", "list3", "list4", "list5", "list6", "list7", "list8", "list9", "list10"]
    let references_lower_int = [0,2,4,5,7,9,10,12,14,16]
    let references_upper_int = [1,3,6,8,11,13,15]
    
    //Core Data setting
    let SongsListVC = SongsListViewController()
    let CoreDataVC = CoreDataManage()
    let AccompanyVC = Accompany()
    let SettingVC = SettingViewController()
    
    let zero = [0,0,0,0,0]
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //keyboard playing
    var isPlaying = true
    
    //timer coefficient
    var timer = Timer()
    var count = 0
    var count_for_compare = 0
    var isTimeRunning = false
    var resumeTap = 0
    
    @IBOutlet weak var songs_list_btn: UIButton!
    @IBOutlet weak var setting_btn: UIButton!
    @IBOutlet weak var piano_keyboard: UIImageView!
    @IBOutlet weak var Volume_slider: UISlider!
    @IBOutlet weak var record_btn: UIButton!
    @IBOutlet weak var time_count: UILabel!
    @IBOutlet weak var stop_replay_btn: UIButton!
    @IBOutlet weak var stop_record_replay_btn: UIButton!
    @IBOutlet weak var accompany_switch: UISwitch!
    @IBOutlet weak var following_btn: UIButton!
    @IBOutlet weak var thinking_head: UIImageView!
    @IBOutlet weak var thinking_loading: UIActivityIndicatorView!
    @IBOutlet weak var thinkint_bulb: UIImageView!
    @IBOutlet weak var song_name_label: UILabel!
    @IBOutlet weak var recordTimerBar: UIProgressView!
    @IBOutlet weak var loading_replay: UIActivityIndicatorView!
    
    //melody record
    var melody_string = [String]()
    var record_number = 0
    var melody_array = [[Int]]()
    var start_record = false
    var melody_record_buffer = [0,0,0,0,0]
    var replay_start = false
    
    //convert index
    var convert = 0
    
    //accompany
    var accompany_isOn = false
    var melody_array_for_compare = [[Int]]()
    var isFollowing = false
    var follow_current_count = 0
    var tap_change_for_following = 1
    var melody_array_for_following = [[Int]]()
    var last_following_array_count = 0
    var following_array_current_notes_amount = 0
    var first_10_notes_array = [[[Int]]]()
    
    //notes
    var notes = [Int]()
    var notes_result = [Int]()
    
    //replay
    var PianoDefaults = UserDefaults.standard
    var replay_or_replace_flag = 1
    var replay_signal = false
    var replay_current_count = 0
    var tap_change = 1
    open var song_number = -1
    var stop_replay_record_signal = false
    var stop_replay_song_signal = true
    var replay_current_count_for_songlist = 0
    var tap_change_for_songlist = 1
    var melody_array_for_replay = [[Int]]()

    //volume
    var volume_detect = 0
    
    //key down imageview
    @IBOutlet var upper_key_down: [UIImageView]!
    @IBOutlet var lower_key_down: [UIImageView]!
    
    var players = [URL:AVAudioPlayer]()
    var duplicatePlayers = [AVAudioPlayer?]()
    
    // Upper and Lower keys size ratio
    let upper_size = [0, 56, 57, 54, 57, 68, 69, 58, 59, 59, 69, 69, 58, 54, 58, 54, 59]
    let lower_size = [0, 84, 105, 106, 104, 104, 105, 105, 104, 105]
    var upper_size_sum = [Int](repeating: 0, count: 17)
    var lower_size_sum = [Int](repeating: 0, count: 10)
    var upper_ratio = [Double]()
    var lower_ratio = [Double]()
    
    //coordination beginning value
    private var startX: Double = 0
    private var startY: Double = 0
    
    // touch position
    var upper_pos = [Double]()
    var lower_pos = [Double]()
    var keyboard_state = [Int](repeating: 0, count: 17)
    
    //multi touch event
    var fingers = [UITouch?](repeating: nil, count: 5)
    var fingers_beginning = [Double](repeating: 0.0, count: 5)
    var multi_touch = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for touch in touches{
            let point = touch.location(in: piano_keyboard)
            for (index,finger)  in fingers.enumerated() {
                if finger == nil {
                    fingers[index] = touch
                    
                    if isPlaying == true && isFollowing == false {
                        touchDetecor(x: Double(point.x), y: Double(point.y), pos: "B")
                     }
                    break
                }
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            let point = touch.location(in: piano_keyboard)
            for (index, finger) in fingers.enumerated() {
                if let finger = finger, finger == touch {
                    let height: Double = Double(piano_keyboard!.frame.size.height)
                    let keyboard_height_size = height / 2
                    
                    if isPlaying == true && isFollowing == false {
                        var init_node = 0
                        var compared_node = 0
                        
                        if Double(point.y) >= 0 && Double(point.y) < keyboard_height_size {
                            for i in 1...16 {
                                if fingers_beginning[index] < upper_pos[i] {
                                    init_node = i - 1
                                    break
                                } else if fingers_beginning[index] > upper_pos[16] {
                                    init_node = 16
                                    break
                                }
                            }
                            
                            for i in 1...16 {
                                if Double(point.x) < upper_pos[i] {
                                    compared_node = i - 1
                                    break
                                } else if Double(point.x) > upper_pos[16] {
                                    compared_node = 16
                                    break
                                }
                            }
                            
                            if init_node != compared_node {
                                upper_key_down[init_node].isHidden = true
                                fingers_beginning[index] = Double(point.x)
                                touchDetecor(x: Double(point.x), y: Double(point.y), pos: "B")
                            }
                        } else if Double(point.y) > keyboard_height_size  && Double(point.y) < keyboard_height_size * 2 {
                            var init_node = 0
                            var compared_node = 0
                            
                            for i in 1...9 {
                                if fingers_beginning[index] < lower_pos[i] {
                                    init_node = i - 1
                                    break
                                } else if fingers_beginning[index] > lower_pos[9] {
                                    init_node = 9
                                    break
                                }
                            }
                            
                            for i in 1...9 {
                                if Double(point.x) < lower_pos[i] {
                                    compared_node = i - 1
                                    break
                                } else if Double(point.x) > lower_pos[9] {
                                    compared_node = 9
                                    break
                                }
                            }
                            
                            if init_node != compared_node {
                                lower_key_down[init_node].isHidden = true
                                fingers_beginning[index] = Double(point.x)
                                touchDetecor(x: Double(point.x), y: Double(point.y), pos: "B")
                            }
                        }
                    }
                    break
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for touch in touches {
            let point = touch.location(in: piano_keyboard)
            for (index,finger) in fingers.enumerated() {
                if let finger = finger, finger == touch {
                    fingers[index] = nil
                    if isPlaying == true && isFollowing == false {
                        touchDetecor(x: Double(point.x), y: Double(point.y), pos: "E")
                    }
                    break
                }
            }
        }
    }
    
    @objc func tapHandler(gesture: UITapGestureRecognizer) {
        if isPlaying == true && isFollowing == false {
            let cgpoint = gesture.location(in: piano_keyboard)
            let height: Double = Double(piano_keyboard!.frame.size.height)
            let keyboard_height_size = height / 2
            
            let touchX: Double = Double(cgpoint.x)
            let touchY: Double = Double(cgpoint.y)
            
            if gesture.state == .began {
                touchDetecor(x: touchX, y: touchY, pos: "B")
                startX = touchX
            } else if gesture.state == .changed {
                var init_node = 0
                var compared_node = 0
                
                if touchY >= 0.0 && touchY < keyboard_height_size {
                    for i in 1...16 {
                        if startX < upper_pos[i] {
                            init_node = i - 1
                            break
                        } else if startX > upper_pos[16] {
                            init_node = 16
                            break
                        }
                    }
                    
                    for i in 1...16 {
                        if touchX < upper_pos[i] {
                            compared_node = i - 1
                            break
                        } else if touchX > upper_pos[16] {
                            compared_node = 16
                            break
                        }
                    }
                    
                    if init_node != compared_node {
                        upper_key_down[init_node].isHidden = true
                        startX = touchX
                        touchDetecor(x: touchX, y: touchY, pos: "B")
                    }
                }
                
                if touchY >= keyboard_height_size && touchY < keyboard_height_size * 2.0 {
                    var init_node = 0
                    var compared_node = 0
                    
                    for i in 1...9 {
                        if startX < lower_pos[i] {
                            init_node = i - 1
                            break
                        } else if startX > lower_pos[9] {
                            init_node = 9
                            break
                        }
                    }
                    for i in 1...9 {
                        if touchX < lower_pos[i] {
                            compared_node = i - 1
                            break
                        } else if touchX > lower_pos[9] {
                            compared_node = 9
                            break
                        }
                    }
                    
                    if init_node != compared_node {
                        lower_key_down[init_node].isHidden = true
                        startX = touchX
                        touchDetecor(x: touchX, y: touchY, pos: "B")
                    }
                }
            } else if gesture.state == .ended {
                touchDetecor(x: touchX, y: touchY, pos: "E")
                if piano_keyboard.isHighlighted == false { for i in upper_key_down { i.isHidden = true } }
            } else if gesture.state == .cancelled {
                for i in upper_key_down { i.isHidden = true }
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let width: Double = Double(piano_keyboard!.frame.size.width)
       
        upper_pos.removeAll()
        lower_pos.removeAll()
        
        for i in 0...16 { upper_pos.append(upper_ratio[i] * width) }
        for i in 0...9 { lower_pos.append(lower_ratio[i] * width) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Refresh the image of the song list image every time
        CoreDataVC.getData()
        update_song_list_image()
        
        var volume_current = Float(1)
        
        if let number = PianoDefaults.object(forKey: "replay_number") {
            song_number = number as! Int
        } else {
            song_number = -1
        }
        
        if let buffer = PianoDefaults.object(forKey: "volume") {
            volume_current = buffer as! Float
        } else {
            volume_current = Float(1)
        }
        
        Volume_slider.value = volume_current
        
        time_count.isHidden = true
        thinking_loading.color = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
        loading_replay.color = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        
        if song_number >= 0 {
            clearChannel()
            disableGesture()
            record_btn.isHidden = true
            stop_replay_btn.isHidden = false
            stop_replay_song_signal = false
            melody_array_for_replay = develope_melody_array_and_play(number: song_number)
            PianoDefaults.set(-1, forKey: "replay_number")
            PianoDefaults.synchronize()
        }
        
        for i in 1...16 { upper_size_sum[i] = upper_size_sum[i - 1] + upper_size[i] }
        for i in 1...9 { lower_size_sum[i] = lower_size_sum[i - 1] + lower_size[i] }
        
        for i in 0...16 { upper_ratio.append(Double(upper_size_sum[i]) / Double(1009)) }
        for i in 0...9 { lower_ratio.append(Double(lower_size_sum[i]) / Double(1026)) }

        // Add gesture
        addGesture()
        
        // Pregress color reset
        recordTimerBar.progressTintColor = UIColor.green
        
        // One Timer to control all function
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { (timer) in self.TimerController()}
    }
    
    // Add Delegate to remove the audio files which has finished
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let index = duplicatePlayers.firstIndex(of: player) {
            print(index)
            duplicatePlayers.remove(at: index)
        }
    }
    
    func saveMelody(note_numb: Int) {
        if start_record == true {
            melody_array[count - 1].append(note_numb)
        } else if accompany_isOn == true {
            var melody_sub_array = [Int]()
            melody_sub_array.append(note_numb)
            if count_for_compare != 0 { melody_array_for_compare[count_for_compare - 1] = melody_sub_array }
        }
    }
    
    func touchDetecor(x: Double, y: Double, pos: String) {
        let keyboard_height: Double = Double(piano_keyboard!.frame.size.height)
                
        if pos == "B" {
            if y >= 0.0 && y < keyboard_height / 2 {
                for i in 1...16 {
                    if x < upper_pos[i] {
                        upper_key_down[i - 1].isHidden = false
                        play(note: references_upper[i - 1])
                        saveMelody(note_numb: i)
                        keyboard_state[i - 1] = 1
                        break
                    } else if x > upper_pos[16] {
                        upper_key_down[16].isHidden = false
                        play(note: references_upper[16])
                        saveMelody(note_numb: 17)
                        keyboard_state[16] = 1
                        break
                    }
                }
            } else if y >= keyboard_height / 2 && y <= keyboard_height {
                for i in 1...9 {
                    if x < lower_pos[i] {
                        lower_key_down[i - 1].isHidden = false
                        play(note: references_lower[i - 1])
                        saveMelody(note_numb: references_lower_int[i - 1] + 1)
                        keyboard_state[i - 1] = 1
                        break
                    } else if x > lower_pos[9] {
                        lower_key_down[9].isHidden = false
                        play(note: references_lower[9])
                        saveMelody(note_numb: references_lower_int[9] + 1)
                        keyboard_state[9] = 1
                        break
                    }
                }
            }
        } else if pos == "E" {
            if y >= 0.0 && y < keyboard_height / 2 {
                for i in 1...16 {
                    if x < upper_pos[i] {
                        upper_key_down[i - 1].isHidden = true
                        saveMelody(note_numb: i + 50)
                        keyboard_state[i - 1] = 0
                        break
                    } else if x > upper_pos[16] {
                        upper_key_down[16].isHidden = true
                        saveMelody(note_numb: 67)
                        keyboard_state[16] = 0
                        break
                    }
                }
            } else if y >= keyboard_height / 2 && y <= keyboard_height {
                for i in 1...9 {
                    if x < lower_pos[i] {
                        lower_key_down[i - 1].isHidden = true
                        saveMelody(note_numb: references_lower_int[i - 1] + 51)
                        keyboard_state[i - 1] = 0
                        break
                    } else if x > lower_pos[9] {
                        lower_key_down[9].isHidden = true
                        saveMelody(note_numb: references_lower_int[9] + 51)
                        keyboard_state[9] = 0
                        break
                    }
                }
            }
        }
    }
    
    func TimerController() {
        if replay_signal == true { ticker_tap_down() }
        if stop_replay_song_signal == false { ticker_replay() }
        if accompany_isOn == true && melody_array_for_compare.count > 0 { go_to_accompanyVC_to_compare_notes() }
        if isFollowing == true { follow_playing() }
        if accompany_isOn == true { add_zero_to_melody_array_for_compare() }
        if replay_start == true {
            //print(melody_array)
            melody_array = filter(temp_array: melody_array)
            //print(melody_array)
            replay_after_record()
            replay_start = false
        }
    }
    
    //home indicator hidden
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func addGesture() {
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(tapHandler))
        tap.minimumPressDuration = 0
        piano_keyboard.addGestureRecognizer(tap)
        piano_keyboard.isUserInteractionEnabled = true
        
    }
    
    func disableGesture() {
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(tapHandler))
        piano_keyboard.removeGestureRecognizer(tap)
        piano_keyboard.isUserInteractionEnabled = false
    }
    
    func clearChannel() {
        for i in players {
            i.value.stop()
            i.value.currentTime = 0
        }
        players.removeAll()
    }
    
    func update_song_list_image() {
        CoreDataVC.getData()
        let song_list_show_amount = CoreDataVC.songs.count
        let image_show_songs_amount = list_image[song_list_show_amount]
        
        songs_list_btn.setImage(UIImage(named: image_show_songs_amount), for: .normal)
        
    }
    
    func add_zero_to_melody_array_for_compare() {
        count_for_compare += 1
        melody_array_for_compare.append(melody_record_buffer)
    }
    
    func NoneZeroAmount(melody: [[Int]]) -> Int {
        var result_amount = 0
        for i in melody {
            if i != zero { result_amount += 1 }
        }
        return result_amount
    }
    
    func go_to_accompanyVC_to_compare_notes() {
        
        if NoneZeroAmount(melody: melody_array_for_compare) > 1 {
            thinkint_bulb.isHidden = true
            thinking_head.isHidden = false
            thinking_loading.isHidden = false
        }
        
        if NoneZeroAmount(melody: melody_array_for_compare) > 9 && accompany_isOn == true {
            var compare_song_number = -4
            let temp_melody_array_for_compare = filter(temp_array: melody_array_for_compare)
            
            (compare_song_number, last_following_array_count, following_array_current_notes_amount) = AccompanyVC.comparison(temp_array: temp_melody_array_for_compare, temp_array_count: last_following_array_count)
            
            if compare_song_number ==  -2 {
                //do nothing untill we get the message that we want
                return
            } else if compare_song_number == -3 {
                thinking_loading.isHidden = true
                thinkint_bulb.image = UIImage(named: "no_idea")
                thinkint_bulb.isHidden = false
                follow_current_count = 0
                tap_change_for_following = 1
                last_following_array_count = 0
                count_for_compare = 0
                following_array_current_notes_amount = 0
                melody_array_for_following.removeAll()
                melody_array_for_compare.removeAll()
            } else if compare_song_number >= 0 {
                disableGesture()
                accompany_isOn = false
                for i in upper_key_down { i.isHidden = true }
                melody_array_for_following = creat_following_melody_array(index: compare_song_number)
                let haha = last_following_array_count
                let buffer = melody_array_for_following
                var number = 0
                var start_number = 0
                while number != haha  {
                    if buffer[start_number] == zero {
                        start_number += 1
                    } else {
                        for i in buffer[start_number] {
                            if i < 20 && i > 0 {
                                number += 1
                                break
                            }
                        }
                        start_number += 1
                    }
                }
                follow_current_count = start_number + 1
                isFollowing = true
                following_array_current_notes_amount = 0
                thinking_loading.isHidden = true
                thinkint_bulb.image = UIImage(named: "bulb")
                thinkint_bulb.isHidden = false
                record_btn.isHidden = true
                following_btn.isHidden = false
            } else if compare_song_number == -1 {
                thinkint_bulb.isHidden = true
                thinking_head.isHidden = false
                thinking_loading.isHidden = false
                accompany_switch.isOn = false
                isFollowing = false
                isPlaying = true
                accompany_isOn = false
                follow_current_count = 0
                tap_change_for_following = 1
                last_following_array_count = 0
                count_for_compare = 0
                following_array_current_notes_amount = 0
                melody_array_for_following.removeAll()
                melody_array_for_compare.removeAll()
            }

        }
    }
    
    func creat_following_melody_array(index: Int) -> [[Int]] {
        isPlaying = false
        
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Melody")
        let fetchRequest_name = NSFetchRequest<NSFetchRequestResult>(entityName: "Songs")
        var melody_string = [String]()
        var melody_int  = [[Int]]()
        var melody_int_buffer = [Int]()
        var melody_result = [[Int]]()
        
        do {
            var result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            var result_name = try managedContext.fetch(fetchRequest_name) as! [NSManagedObject]
            let melody = result[index].value(forKey: "melody") as! String
            let name = result_name[index].value(forKey: "song_name") as! String
            
            song_name_label.text = name
            song_name_label.isHidden = false
            
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
                if melody_int[i][0] == 99 {
                    var zero_index = melody_int[i][3] * 100 + melody_int[i][4]
                    while zero_index > 0 {
                        melody_result.append(zero)
                        zero_index = zero_index - 1
                    }
                } else {
                    melody_result.append(melody_int[i])
                }
            }
        } catch {
            print("failed to get melody!!!")
        }
        
        return melody_result
    }
    
    func follow_playing() {
        
        isFollowing = true
        songs_list_btn.isEnabled = false
        setting_btn.isEnabled = false
        accompany_switch.isEnabled = false
        
        if melody_array_for_following[follow_current_count] == zero {
            follow_current_count += 1
        } else {
            if tap_change_for_following == 0 {
                for i in melody_array_for_following[follow_current_count] {
                    if i != 0 && i < 20 { upper_key_down[i - 1].isHidden = false }
                }
                follow_current_count += 1
                tap_change_for_following = 1
            } else if tap_change_for_following == 1 {
                for j in melody_array_for_following[follow_current_count] {
                    if j != 0 && j < 20 {
                        for i in upper_key_down { i.isHidden = true }
                        play(note: references_upper[j - 1])
                    }
                }
                tap_change_for_following = 0
            }
        }
        
        if follow_current_count == melody_array_for_following.count {
            accompany_isOn = true
            isFollowing = false
            isPlaying = true
            count_for_compare = 0
            follow_current_count = 0
            tap_change_for_following = 1
            last_following_array_count = 0
            following_array_current_notes_amount = 0
            thinkint_bulb.isHidden = true
            following_btn.isHidden = true
            thinking_head.isHidden = false
            thinking_loading.isHidden = false
            song_name_label.isHidden = true
            accompany_switch.isEnabled = true
            record_btn.isEnabled = false
            record_btn.isHidden = false
            for i in upper_key_down { i.isHidden = true }
            melody_array_for_following.removeAll()
            melody_array_for_compare.removeAll()
            addGesture()
        }
    }
    
    func ticker_tap_down() {
        var replay_detect = false
        var count_not_zero = 0
        isPlaying = false
        
        for i in 0...melody_array.count - 1 {
            if melody_array[i] == zero && i != melody_array.count - 1 { continue }
            else if melody_array[i] != zero {
                count_not_zero += 1
            }
            
            if count_not_zero > 0 {
                replay_detect = true
                replay_signal = true
             break
            }
            
            // No record in the melody array
            if replay_detect == false && i == melody_array.count - 1 {
                clearChannel()
                addGesture()
                isPlaying = true
                timer.invalidate()
                count = 0
                time_count.text = "00 : 00 : 00"
                melody_array.removeAll()
                notes_result.removeAll()
                replay_signal = false
                record_btn.isHidden = false
                stop_record_replay_btn.isHidden = true
                record_btn.setImage(UIImage(named: "record"), for: .normal)
                record_btn.isHidden = false
                stop_record_replay_btn.isHidden = true
                accompany_switch.isEnabled = true
                songs_list_btn.isEnabled = true
                setting_btn.isEnabled = true
            }
        }
        
        if replay_detect == true {
            stop_record_replay_btn.isEnabled = true
            if replay_signal == true, stop_replay_record_signal == false {
                if melody_array[replay_current_count] == zero && replay_current_count < melody_array.count {
                    replay_current_count += 1
                } else if melody_array[replay_current_count] != zero && replay_current_count < melody_array.count  {
                    if tap_change == 0 {
                        for i in melody_array[replay_current_count] {
                            if i != 0 && i < 20 { upper_key_down[i - 1].isHidden = false }
                        }
                        replay_current_count += 1
                        tap_change = 1
                    } else if tap_change == 1 {
                        for j in melody_array[replay_current_count] {
                            if j != 0 && j < 20 {
                                for i in upper_key_down { i.isHidden = true }
                                play(note: references_upper[j - 1])
                            }
                            if j > 20 {
                                upper_key_down[j - 51].isHidden = true
                            }
                        }
                        tap_change = 0
                    }
                }
                
                if replay_current_count != melody_array.count - 1 {
                    replay_signal = true
                }
                
                if replay_current_count == melody_array.count {
                    replay_signal = false
                    replay_current_count = 0
                    tap_change = 1
                    record_btn.isHidden = false
                    
                    //convert array into string(melody & notes)
                    let first_10_notes = convertFirst_10_to_String(melodyArray: melody_array)
                    let melody_to_coredata = convertArrayToString()
                    let notes_to_coredata = convert_array_to_String(array: notes_result)
                    var song_detect = CoreDataVC.detect_song(temp_array: make_pure_array())
                    var NoSignal = false
                    
                    //detect whether there are more than ten songs in list
                    if CoreDataVC.songs.count == 10  {
                        let alert = UIAlertController(title: "Warning", message: "You should delete one song from Song List, and then record your new song!!", preferredStyle: .alert)
                        let OkAction = UIAlertAction(title: "OK", style: .default) {
                            [unowned self] action in
                            
                            self.timer.invalidate()
                            self.convert = 0
                            self.count = 0
                            self.time_count.text = "00 : 00 : 00"
                            self.melody_array.removeAll()
                            self.notes_result.removeAll()
                            self.record_btn.isHidden = false
                            self.stop_record_replay_btn.isHidden = true
                            self.replay_current_count = 0
                            self.accompany_switch.isEnabled = true
                            self.songs_list_btn.isEnabled = true
                            self.setting_btn.isEnabled = true
                            self.stop_replay_record_signal = false
                            self.isPlaying = true
                            self.addGesture()
                            self.update_song_list_image()
                        }
                        
                        alert.addAction(OkAction)
                        present(alert, animated: true)
                    }
                    
                    //clear all key down
                    for i in upper_key_down { i.isHidden = true }
                    
                    if song_detect == false {
                        let song_name = CoreDataVC.songs[self.CoreDataVC.row]
                        let song = song_name.value(forKeyPath: "song_name") as? String
                        let alert_name = "Is it " + song!
                        let alert = UIAlertController(title: alert_name, message: "" , preferredStyle: .alert)
                        
                        record_btn.isHidden = true
                        
                        let YesAction = UIAlertAction(title: "Yes", style: .default) {
                            [unowned self] action in
                            
                            //reset data in core data
                            //let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            let managedContext = self.appDelegate.persistentContainer.viewContext
                            let fetchRequest_melody = NSFetchRequest<NSFetchRequestResult>(entityName: "Melody")
                            let ferchRequest_first = NSFetchRequest<NSFetchRequestResult>(entityName: "First_10")
                            let fetchRequest_note = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                            let fetchRequest_name = NSFetchRequest<NSFetchRequestResult>(entityName: "Songs")
                            
                            
                            do {
                                let results_melody = try managedContext.fetch(fetchRequest_melody) as? [NSManagedObject]
                                let results_note = try managedContext.fetch(fetchRequest_note) as? [NSManagedObject]
                                let results_name = try managedContext.fetch(fetchRequest_name) as? [NSManagedObject]
                                let results_first_10 = try managedContext.fetch(ferchRequest_first) as? [NSManagedObject]
                                
                                if results_melody?.count != 0 { results_melody![self.CoreDataVC.row].setValue(melody_to_coredata, forKey: "melody") }
                                if results_first_10?.count != 0 { results_first_10![self.CoreDataVC.row].setValue(first_10_notes, forKey: "first_10_notes") }
                                if results_note?.count != 0 { results_note![self.CoreDataVC.row].setValue(notes_to_coredata, forKey: "notes") }
                                if results_name?.count != 0 { results_name![self.CoreDataVC.row].setValue(song, forKey: "song_name") }
                            } catch {
                                print("Fetch Failed: \(error)")
                            }
                            
                            do {
                                try managedContext.save()
                            }
                            catch {
                                print("Saving Core Data Failed: \(error)")
                            }
                            
                            //reset all coefficient
                            self.timer.invalidate()
                            self.convert = 0
                            self.count = 0
                            self.replay_current_count = 0 ////
                            self.time_count.text = "00 : 00 : 00"
                            self.melody_array.removeAll()
                            self.notes_result.removeAll()
                            self.record_btn.isHidden = false
                            self.stop_record_replay_btn.isHidden = true
                            self.accompany_switch.isEnabled = true
                            self.songs_list_btn.isEnabled = true
                            self.setting_btn.isEnabled = true
                            self.stop_replay_record_signal = false
                            self.update_song_list_image()
                            self.isPlaying = true
                            self.addGesture()
                        }
                        
                        let NoAction = UIAlertAction(title: "No", style: .default) {
                            [unowned self] action in
                            
                            self.showAlertAfterTapNo()
                            self.update_song_list_image()
                            self.isPlaying = true
                            
                            song_detect = true
                            NoSignal = true
                        }
                        
                        alert.addAction(YesAction)
                        alert.addAction(NoAction)
                        
                        present(alert, animated: true)
                    }
                    
                    if song_detect == true || NoSignal == true {
                        
                        var same_song_name_number = 0
                        
                        //save the audio or not(showing alert)
                        let alert = UIAlertController(title: "New Song", message: "Add a new name", preferredStyle: .alert)
                        
                        record_btn.isHidden = true
                        
                        let saveAction = UIAlertAction(title: "Save", style: .default) {
                            [unowned self] action in
                            guard let textField = alert.textFields?.first,
                                let nameToSave = textField.text else {
                                    return
                            }
                            
                            if self.CoreDataVC.songs.count == 0 {
                                same_song_name_number = -1
                            } else {
                                for i in 0...self.CoreDataVC.songs.count - 1 {
                                    if self.CoreDataVC.songs[i].value(forKey: "song_name") as? String == nameToSave {
                                        same_song_name_number = i
                                        break
                                    } else if self.CoreDataVC.songs[i].value(forKey: "song_name") as? String != nameToSave && i == self.CoreDataVC.songs.count - 1 {
                                        same_song_name_number = -1
                                    }
                                }
                            }
                            
                            if same_song_name_number == -1 {
                                let group = DispatchGroup()
                                group.enter()
                                
                                DispatchQueue.main.async {
                                    self.save(name: nameToSave)
                                    self.savefirst_10_notes(string_to_save: first_10_notes)
                                    self.add_Audio_to_CoreData(audio: melody_to_coredata)
                                    self.add_notes_to_CoreData(notes: notes_to_coredata)
                                    group.leave()
                                }
                                
                                group.notify(queue: .main) {
                                    self.update_song_list_image()
                                    self.isPlaying = true
                                    self.addGesture()
                                }
                            } else {
                                
                                let alert_2 = UIAlertController(title: "Replace Old song with New one", message: "", preferredStyle: .alert)
                                
                                let YesAction = UIAlertAction(title: "Yes", style: .default) {
                                    [unowned self] action in
                                    self.cover(name: nameToSave, melody: melody_to_coredata, notes: notes_to_coredata, first_10: first_10_notes, same_song_name_number: same_song_name_number)
                                    self.update_song_list_image()
                                    self.isPlaying = true
                                    self.addGesture()
                                }
                                
                                let NoAction = UIAlertAction(title: "No", style: .default) {
                                    [unowned self] action in
                                    
                                    //detect whether there are more than ten songs in list
                                    if self.CoreDataVC.songs.count == 10  {
                                        let alert = UIAlertController(title: "Warning", message: "You should delete one song from Song List, and then record your new song!!", preferredStyle: .alert)
                                        let OkAction = UIAlertAction(title: "OK", style: .default) {
                                            [unowned self] action in
                                            
                                            self.timer.invalidate()
                                            self.count = 0
                                            self.convert = 0
                                            self.time_count.text = "00 : 00 : 00"
                                            self.melody_array.removeAll()
                                            self.notes_result.removeAll()
                                            self.record_btn.isHidden = false
                                            self.stop_record_replay_btn.isHidden = true
                                            self.replay_current_count = 0
                                            self.accompany_switch.isEnabled = true
                                            self.songs_list_btn.isEnabled = true
                                            self.setting_btn.isEnabled = true
                                            self.stop_replay_record_signal = false
                                            self.update_song_list_image()
                                            self.isPlaying = true
                                            self.addGesture()
                                        }
                                        
                                        alert.addAction(OkAction)
                                        self.present(alert, animated: true)
                                    } else {
                                        let group = DispatchGroup()
                                        group.enter()
                                        
                                        DispatchQueue.main.async {
                                            self.save(name: nameToSave)
                                            self.savefirst_10_notes(string_to_save: first_10_notes)
                                            self.add_Audio_to_CoreData(audio: melody_to_coredata)
                                            self.add_notes_to_CoreData(notes: notes_to_coredata)
                                            group.leave()
                                        }
                                        
                                        group.notify(queue: .main) {
                                            self.update_song_list_image()
                                            self.isPlaying = true
                                            self.addGesture()
                                        }
                                    }
                                }
                                
                                alert_2.addAction(YesAction)
                                alert_2.addAction(NoAction)
                                
                                self.present(alert_2, animated: true)
                            }
                            
                            //reset all coefficient
                            self.timer.invalidate()
                            self.count = 0
                            self.convert = 0
                            self.time_count.text = "00 : 00 : 00"
                            self.melody_array.removeAll()
                            self.notes_result.removeAll()
                            self.record_btn.isHidden = false
                            self.stop_record_replay_btn.isHidden = true
                            self.replay_current_count = 0
                            self.accompany_switch.isEnabled = true
                            self.songs_list_btn.isEnabled = true
                            self.setting_btn.isEnabled = true
                            self.stop_replay_record_signal = false
                            self.update_song_list_image()
                            self.isPlaying = true
                            self.addGesture()
                        }
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
                            [unowned self] action in
                            
                            self.timer.invalidate()
                            self.count = 0
                            self.convert = 0
                            self.replay_current_count = 0
                            self.time_count.text = "00 : 00 : 00"
                            self.melody_array.removeAll()
                            self.notes_result.removeAll()
                            self.record_btn.isHidden = false
                            self.stop_record_replay_btn.isHidden = true
                            self.accompany_switch.isEnabled = true
                            self.songs_list_btn.isEnabled = true
                            self.setting_btn.isEnabled = true
                            self.stop_replay_record_signal = false
                            self.isPlaying = true
                            self.addGesture()
                            self.update_song_list_image()
                        }
                        
                        alert.addTextField()
                        alert.addAction(saveAction)
                        alert.addAction(cancelAction)
                        
                        present(alert, animated: true)
                        stop_record_replay_btn.isHidden = true
                    }
                    record_btn.setImage(UIImage(named: "record"), for: .normal)
                }
            }
        }
        return
    }
    
    func showAlertAfterTapNo() {
        
        var same_song_name_number = 0
        
        //convert array into string(melody & notes)
        let first_10_notes = convertFirst_10_to_String(melodyArray: melody_array)
        let melody_to_coredata = convertArrayToString()
        let notes_to_coredata = convert_array_to_String(array: notes_result)
        
        for i in upper_key_down { i.isHidden = true }
        
        let alert = UIAlertController(title: "New Song", message: "Add a new name", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [unowned self] action in
            guard let textField = alert.textFields?.first,
                let nameToSave = textField.text else {
                    return
            }
            
            if self.CoreDataVC.songs.count == 0 {
                same_song_name_number = -1
            } else {
                for i in 0...self.CoreDataVC.songs.count - 1 {
                    if self.CoreDataVC.songs[i].value(forKey: "song_name") as? String == nameToSave {
                        same_song_name_number = i
                        break
                    } else if self.CoreDataVC.songs[i].value(forKey: "song_name") as? String != nameToSave && i == self.CoreDataVC.songs.count - 1 {
                        same_song_name_number = -1
                    }
                }
            }
            
            if same_song_name_number == -1 {
                //save data to core data
                DispatchQueue.global().async {
                    self.save(name: nameToSave)
                    self.savefirst_10_notes(string_to_save: first_10_notes)
                    self.add_Audio_to_CoreData(audio: melody_to_coredata)
                    self.add_notes_to_CoreData(notes: notes_to_coredata)
                }
                self.update_song_list_image()
            } else {
                let alert_2 = UIAlertController(title: "Replace old song with new one", message: "", preferredStyle: .alert)
                
                let YesAction = UIAlertAction(title: "Yes", style: .default) {
                    [unowned self] action in
                    self.cover(name: nameToSave, melody: melody_to_coredata, notes: notes_to_coredata, first_10: first_10_notes, same_song_name_number: same_song_name_number)
                    self.update_song_list_image()
                }
                
                let NoAction = UIAlertAction(title: "No", style: .default) {
                    [unowned self] action in
                    
                    //detect whether there are more than ten songs in list
                    if self.CoreDataVC.songs.count >= 10  {
                        let alert = UIAlertController(title: "Warning", message: "You should delete one song from Song List, and then record your new song!!", preferredStyle: .alert)
                        let OkAction = UIAlertAction(title: "OK", style: .default) {
                            [unowned self] action in
                            
                            self.timer.invalidate()
                            self.count = 0
                            self.convert = 0
                            self.replay_current_count = 0
                            self.time_count.text = "00 : 00 : 00"
                            self.melody_array.removeAll()
                            self.notes_result.removeAll()
                            self.record_btn.isHidden = false
                            self.stop_record_replay_btn.isHidden = true
                            self.accompany_switch.isEnabled = true
                            self.songs_list_btn.isEnabled = true
                            self.setting_btn.isEnabled = true
                            self.stop_replay_record_signal = false
                            self.addGesture()
                        }
                        
                        alert.addAction(OkAction)
                        self.present(alert, animated: true)
                    } else {
                        let group = DispatchGroup()
                        group.enter()
                        
                        DispatchQueue.main.async {
                            self.save(name: nameToSave)
                            self.savefirst_10_notes(string_to_save: first_10_notes)
                            self.add_Audio_to_CoreData(audio: melody_to_coredata)
                            self.add_notes_to_CoreData(notes: notes_to_coredata)
                            group.leave()
                        }
                        
                        group.notify(queue: .main) {
                            self.update_song_list_image()
                            self.addGesture()
                        }
                    }
                }
                
                alert_2.addAction(YesAction)
                alert_2.addAction(NoAction)
                
                self.present(alert_2, animated: true)
            }
            
            //reset all coefficient
            self.timer.invalidate()
            self.count = 0
            self.convert = 0
            self.time_count.text = "00 : 00 : 00"
            self.melody_array.removeAll()
            self.notes_result.removeAll()
            self.record_btn.isHidden = false
            self.stop_record_replay_btn.isHidden = true
            self.replay_current_count = 0
            self.accompany_switch.isEnabled = true
            self.songs_list_btn.isEnabled = true
            self.setting_btn.isEnabled = true
            self.stop_replay_record_signal = false
            self.update_song_list_image()
            self.addGesture()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            [unowned self] action in
            
            self.timer.invalidate()
            self.count = 0
            self.convert = 0
            self.time_count.text = "00 : 00 : 00"
            self.melody_array.removeAll()
            self.notes_result.removeAll()
            self.record_btn.isHidden = false
            self.stop_record_replay_btn.isHidden = true
            self.replay_current_count = 0
            self.accompany_switch.isEnabled = true
            self.songs_list_btn.isEnabled = true
            self.setting_btn.isEnabled = true
            self.stop_replay_record_signal = false
            self.addGesture()
            self.update_song_list_image()
        }
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)

        stop_record_replay_btn.isHidden = true
        record_btn.setImage(UIImage(named: "record"), for: .normal)
    }
    
    func cover(name: String, melody: String, notes: String, first_10: String, same_song_name_number: Int) {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest_melody = NSFetchRequest<NSFetchRequestResult>(entityName: "Melody")
        let ferchRequest_first = NSFetchRequest<NSFetchRequestResult>(entityName: "First_10")
        let fetchRequest_note = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        let fetchRequest_name = NSFetchRequest<NSFetchRequestResult>(entityName: "Songs")
        
        do {
            let results_melody = try managedContext.fetch(fetchRequest_melody) as? [NSManagedObject]
            let results_first_10 = try managedContext.fetch(ferchRequest_first) as? [NSManagedObject]
            let results_note = try managedContext.fetch(fetchRequest_note) as? [NSManagedObject]
            let results_name = try managedContext.fetch(fetchRequest_name) as? [NSManagedObject]
            
            results_melody![same_song_name_number].setValue(melody, forKey: "melody")
            results_first_10![same_song_name_number].setValue(first_10, forKey: "first_10_notes")
            results_note![same_song_name_number].setValue(notes, forKey: "notes")
            results_name![same_song_name_number].setValue(name, forKey: "song_name")
        } catch {
            print("Fetch Failed: \(error)")
        }
        
        do {
            try managedContext.save()
        }
        catch {
            print("Saving Core Data Failed: \(error)")
        }
    }
    
    func savefirst_10_notes(string_to_save: String) {
        
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "First_10", in: managedContext)!
        let song = NSManagedObject(entity: entity, insertInto: managedContext)
        song.setValue(string_to_save, forKey: "first_10_notes")
        
        do {
            try managedContext.save()
            CoreDataVC.first_10_notes.append(song)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func convertFirst_10_to_String(melodyArray: [[Int]]) -> String {
        var result = ""
        var result_buffer = [String]()
        var buffer_array_for_10_notes = [[Int]]()
        var note_amount = 0
        
        for num in 0...melodyArray.count - 1 {
            if melodyArray[num] != zero && note_amount < 10 {
                var flag = 1
                for i in 0...4 {
                    if melodyArray[num][i] > 20 {
                        flag = 0
                        break
                    }
                }
                if flag == 1 {
                    buffer_array_for_10_notes.append(melodyArray[num])
                    note_amount += 1
                }
            } else if note_amount == 10 || num == melodyArray.count - 1 {
                break
            }
        }
        
        for i in 0...buffer_array_for_10_notes.count - 1 {
            var result_string = ""
            var buffer_temp:String = ""
            for j in 0...4 {
                if (buffer_array_for_10_notes[i][j] < 10) { buffer_temp = String(format:"0%1d",buffer_array_for_10_notes[i][j]) }
                else if (buffer_array_for_10_notes[i][j] >= 10) { buffer_temp = String(format:"%2d",buffer_array_for_10_notes[i][j]) }
                result_string = result_string + buffer_temp
            }
            result_buffer.append(result_string)
        }
        
        for k in result_buffer { result = result + k }
        
        return result
    }
    
    //replay from song list
    func develope_melody_array_and_play(number: Int) -> [[Int]] {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Melody")
        let fetchRequest_name = NSFetchRequest<NSFetchRequestResult>(entityName: "Songs")
        var melody_string = [String]()
        var melody_int  = [[Int]]()
        var melody_int_buffer = [Int]()
        var melody_result = [[Int]]()
        
        do {
            var result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            var result_name = try managedContext.fetch(fetchRequest_name) as! [NSManagedObject]
            let melody = result[number].value(forKey: "melody") as! String
            let name = result_name[number].value(forKey: "song_name") as! String
            
            song_name_label.text = name
            song_name_label.isHidden = false
            
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
                if melody_int[i][0] == 99 {
                    var zero_index = melody_int[i][3] * 100 + melody_int[i][4]
                    while zero_index > 0 {
                        melody_result.append(zero)
                        zero_index = zero_index - 1
                    }
                } else {
                    melody_result.append(melody_int[i])
                }
            }
        } catch {
            print("failed to get melody!!!")
        }
        return melody_result
    }
    
    func ticker_replay() {
        isPlaying = false
        piano_keyboard.isUserInteractionEnabled = false
        
        //in order to stop use other functions
        setting_btn.isEnabled = false
        accompany_switch.isEnabled = false
        songs_list_btn.isEnabled = false
        if melody_array_for_replay[replay_current_count_for_songlist] == zero {
            replay_current_count_for_songlist += 1
        } else {
            if tap_change_for_songlist == 0 {
                for i in melody_array_for_replay[replay_current_count_for_songlist] {
                    if i != 0 && i < 20 { upper_key_down[i - 1].isHidden = false }
                }
                replay_current_count_for_songlist += 1
                tap_change_for_songlist = 1
                
            } else if tap_change_for_songlist == 1 {
                for j in melody_array_for_replay[replay_current_count_for_songlist] {
                    if j != 0 && j < 20 {
                        for i in upper_key_down { i.isHidden = true }
                        play(note: references_upper[j - 1])
                    }
                }
                tap_change_for_songlist = 0
            }
        }
        
        if replay_current_count_for_songlist != melody_array_for_replay.count {
            stop_replay_song_signal = false
        } else {
            addGesture()
            isPlaying = true
            piano_keyboard.isUserInteractionEnabled = true
            song_number = -1
            PianoDefaults.set(song_number, forKey: "replay_number")
            PianoDefaults.synchronize()
            stop_replay_btn.isHidden = true
            record_btn.isHidden = false
            stop_replay_song_signal = true
            replay_current_count_for_songlist = 0
            tap_change_for_songlist = 1
            setting_btn.isEnabled = true
            accompany_switch.isEnabled = true
            songs_list_btn.isEnabled = true
            song_name_label.isHidden = true
            for i in upper_key_down { i.isHidden = true }
        }
        return
    }
    
    //control volume function
    @IBAction func volume_control(_ sender: UISlider) {
       
        for i in duplicatePlayers {
            if i != nil {
                i!.volume = Volume_slider.value
            }
        }
        
        PianoDefaults.set(Volume_slider.value, forKey: "volume")
        PianoDefaults.synchronize()
    }
    
    func play(note: String) {
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: note, ofType: "wav")!)
        
        if duplicatePlayers.count < 16 {
            do {
                
                let duplicatePlayer = try AVAudioPlayer(contentsOf: url)
                //use 'try!' because we know the URL worked before.
                
                duplicatePlayer.delegate = self as AVAudioPlayerDelegate
                //assign delegate for duplicatePlayer so delegate can remove the duplicate once it's stopped playing
                
                self.duplicatePlayers.append(duplicatePlayer)
                //add duplicate to array so it doesn't get removed from memory before finishing
                
                duplicatePlayer.volume = self.Volume_slider.value
                DispatchQueue.global().async {
                    duplicatePlayer.prepareToPlay()
                    duplicatePlayer.play()
                }
                
            } catch {
                print("Could not play sound file(U)")
                print(error)
                clearChannel()
            }
        } else {
            print("upper audio channel >= 16")
        }
    }
    
    func replay_after_record() {
        loading_replay.isHidden = true
        replay_signal = true
    }
    
    func make_pure_array() -> [[Int]] {
        var result_array = [[Int]]()
        
        for array in melody_array {
            if array != zero { result_array.append(array) }
        }
        
        return result_array
    }
    
    func save(name: String) {
        
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Songs", in: managedContext)!
        let song = NSManagedObject(entity: entity, insertInto: managedContext)
        song.setValue(name, forKeyPath: "song_name")
        
        do {
            try managedContext.save()
            CoreDataVC.songs.append(song)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    //add notes to coredata
    func add_notes_to_CoreData(notes: String) {
        
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Note", in: managedContext)!
        let song = NSManagedObject(entity: entity, insertInto: managedContext)
        song.setValue(notes, forKey: "notes")
        
        do {
            try managedContext.save()
            CoreDataVC.songs_notes.append(song)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func filter(temp_array: [[Int]]) -> [[Int]] {
        var melody_array = temp_array
        var buffer_array = [[Int]]()
        
        if melody_array.count > 1 {
            for i in 0...melody_array.count - 2 {
                if melody_array[i] == zero {
                    buffer_array.append(melody_array[i])
                } else if melody_array[i] != zero {
                    var buffer = [Int]()
                    var compare_buffer = 0
                    var search_20 = false
                    var search_50 = false
                    
                    for k in melody_array[i] {
                        if compare_buffer == 2 { break }
                        if search_20 == false && k > 0 && k < 20 {
                            search_20 = true
                            compare_buffer += 1
                        } else if search_50 == false && k > 20 {
                            search_50 = true
                            compare_buffer += 1
                        }
                    }
                    
                    if compare_buffer == 2 {
                        var error_buffer = false
                        for k in 0...melody_array[i].count - 1 {
                            if error_buffer {
                                for m in 0...melody_array[i].count - 1 {
                                    if abs(Double(melody_array[i][k] - melody_array[i][m])) > 40  {
                                        if melody_array[i][m] > melody_array[i][k] {
                                            melody_array[i + 1].append(melody_array[i][m])
                                            melody_array[i][m] = 0
                                        } else {
                                            melody_array[i + 1].append(melody_array[i][k])
                                            melody_array[i][k] = 0
                                        }
                                        error_buffer = true
                                    }
                                }
                            } else {
                                break
                            }
                        }
                    }
                    
                    for j in melody_array[i] { if j > 0 { buffer.append(j) } }
                    
                    if melody_array[i + 1] != zero {
                        var flag = 1
                        for node in melody_array[i + 1] {
                            if node > 20 {
                                flag = 0
                                break
                            }
                        }
                        if flag == 1 {
                            for k in melody_array[i + 1] {
                                if k > 0 { buffer.append(k) }
                            }
                            melody_array[i + 1] = zero //keep from caculating same note again
                        }
                    }
                    
                    var buffer_zero_count = 5 - buffer.count
                    while buffer_zero_count > 0 {
                        buffer.append(0)
                        buffer_zero_count -= 1
                    }
                    buffer_array.append(buffer)
                }
            }
        } else {
            buffer_array = [zero]
        }
        
        return buffer_array
    }
    
    
    func convert_array_to_String(array: [Int]) -> String {
        var result_string = ""
        
        for i in 0...array.count - 1 {
            var buffer_temp: String = ""
            if (array[i] < 10) { buffer_temp = String(format:"0%1d",array[i]) }
            else if (array[i] >= 10) { buffer_temp = String(format:"%2d",array[i]) }
            result_string = result_string + buffer_temp
        }
        return result_string
    }
    
    
    //add melody to coredata
    func add_Audio_to_CoreData(audio: String) {
        
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Melody", in: managedContext)!
        let song = NSManagedObject(entity: entity, insertInto: managedContext)
        song.setValue(audio, forKey: "melody")
        
        do {
            try managedContext.save()
            CoreDataVC.songs_melody.append(song)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    
    func convertArrayToString() -> String {
        var result_string = ""
        
        //detecter(index: convert)
        result_string = compress(array: melody_array)
        
        return result_string
    }
    
    func detecter(index: Int) {
        var buffer = index

        if buffer != melody_array.count {
            if melody_array[buffer].count < 5 {
                melody_array[buffer].append(0)
                detecter(index: buffer)
            } else if melody_array[buffer].count == 5 {
                buffer = buffer + 1
                detecter(index: buffer)
            } else if melody_array[buffer].count > 5 {
                if melody_array[buffer][0] != 0 { melody_array[buffer].remove(at: 0) }
                melody_array[buffer].remove(at: 2)
                detecter(index: buffer)
            }
        }
        return
    }
    
    func compress(array: [[Int]]) -> String {
        var array_buffer = [[Int]]()
        var array_buffer_string = [String]()
        var zero_detect = 0
        var t = 0
        
        while t < array.count {
            if array[t] != zero {
                array_buffer.append(array[t])
                
                //add note in notes array
                for j in array[t] {
                    if j != 0 && array[t][0] < 20 { notes.append(j) }
                }
                t = t + 1
            } else {
                zero_detect += 1
                t = t + 1
                if t < array.count - 1 {
                    if array[t + 1] != zero {
                        array_buffer.append([99, 0, 0, zero_detect / 100, zero_detect % 100 + 1])
                        zero_detect = 0
                    }
                } else if t == array.count - 1 {
                    t = t + 1
                }
            }
        }
        
        for i in notes {
            if i < 20 { notes_result.append(i) }
        }
        
        notes.removeAll()
        
        for i in 0...array_buffer.count - 1 {
            var result_string = ""
            var buffer_temp:String = ""
            for j in 0...4 {
                if (array_buffer[i][j] < 10) { buffer_temp = String(format:"0%1d",array_buffer[i][j]) }
                else if (array_buffer[i][j] >= 10) { buffer_temp = String(format:"%2d",array_buffer[i][j]) }
                result_string = result_string + buffer_temp
            }
            array_buffer_string.append(result_string)
        }
        
        var array_temp: String = ""
        
        for k in array_buffer_string { array_temp = array_temp + k }
        
        return array_temp
    }
    

    func create_first_10_notes_array() -> [[[Int]]] {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "First_10")
        
        var result_for_first_10 = [[[Int]]]()
        CoreDataVC.getData()
        let first_10_notes_count = CoreDataVC.songs.count
        
        if first_10_notes_count > 0 {
            do {
                for number in 0...first_10_notes_count - 1 {
                    
                    var melody_string = [String]()
                    var melody_int  = [[Int]]()
                    var melody_int_buffer = [Int]()
                    var result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                    let melody = result[number].value(forKey: "first_10_notes") as! String
                    
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
                    
                    result_for_first_10.append(melody_int)
                }
            } catch {
                print("failed to get melody!!!")
            }
        } else if first_10_notes_count == 0 {
            result_for_first_10 = [[[0]]]
        }
        return result_for_first_10
    }
    
    //timer setting
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.02, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        count += 1
        recordTimerBar.progress += 0.00011
        melody_array.append(melody_record_buffer)
        let minutes = Int(count) / 3000
        let seconds = Int(count) / 50 % 60
        let fraction = Int(count) * 2 % 100
        time_count.text = String(format: "%02i : %02i : %02i",minutes,seconds,fraction)
        if count == 8500 { recordTimerBar.progressTintColor = UIColor.red }
        if count == 9000 {
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async {
                self.time_count.isHidden = true
                self.resumeTap = 1
                self.timer.invalidate()
                self.start_record = false
                self.record_btn.isHidden = true
                self.stop_record_replay_btn.isEnabled = false
                self.stop_record_replay_btn.isHidden = false
                self.disableGesture()
                self.recordTimerBar.isHidden = true
                self.recordTimerBar.progress = 0.0
                self.recordTimerBar.progressTintColor = UIColor.green
                self.loading_replay.isHidden = false
                self.replay_start = true
                group.leave()
            }
            resumeTap = 1
        }
    }
    
    @IBAction func play_pause_Record(_ sender: Any) {
        if resumeTap == 0 && record_number > 0 {
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async {
                self.time_count.isHidden = true
                self.resumeTap = 1
                self.timer.invalidate()
                self.start_record = false
                self.record_btn.isHidden = true
                self.stop_record_replay_btn.isEnabled = false
                self.stop_record_replay_btn.isHidden = false
                self.disableGesture()
                self.recordTimerBar.isHidden = true
                self.recordTimerBar.progress = 0.0
                self.recordTimerBar.progressTintColor = UIColor.green
                self.loading_replay.isHidden = false
                self.replay_start = true
                group.leave()
            }
            resumeTap = 1
        } else if resumeTap == 1 {
            //detect whether there are more than ten songs in list
            CoreDataVC.getData()
            if CoreDataVC.songs.count == 10  {
                let alert = UIAlertController(title: "Warning", message: "You should delete one song from Song List, and then record your new song!!", preferredStyle: .alert)
                let OkAction = UIAlertAction(title: "OK", style: .default) {
                    [unowned self] action in
                    self.resumeTap = 1
                }
                alert.addAction(OkAction)
                present(alert, animated: true)
            } else {
                addGesture()
                recordTimerBar.isHidden = false
                recordTimerBar.progress = 0.0
                recordTimerBar.progressTintColor = UIColor.green
                time_count.isHidden = false
                accompany_switch.isEnabled = false
                songs_list_btn.isEnabled = false
                setting_btn.isEnabled = false
                start_record = true
                runTimer()
                record_btn.setImage(UIImage(named: "pause"), for: .normal)
                resumeTap = 0
            }
        } else if resumeTap == 0 && record_number == 0 {
            record_number += 1
            resumeTap = 1
        }
    }
    
    @IBAction func pause_replay(_ sender: Any) {
        if stop_replay_song_signal == false {
            clearChannel()
            addGesture()
            isPlaying = true
            piano_keyboard.isUserInteractionEnabled = true
            stop_replay_btn.isHidden = true
            record_btn.isHidden = false
            for i in upper_key_down { i.isHidden = true }
            stop_replay_song_signal = true
            setting_btn.isEnabled = true
            accompany_switch.isEnabled = true
            songs_list_btn.isEnabled = true
            song_name_label.isHidden = true
            PianoDefaults.set(-1, forKey: "replay_number")
            PianoDefaults.synchronize()
        }
    }
    
    @IBAction func stop_record_replay_replay(_ sender: Any) {
        if stop_replay_record_signal == false {
            clearChannel()
            addGesture()
            isPlaying = true
            replay_current_count = melody_array.count - 1
            convert = melody_array.count - 1
            setting_btn.isHidden = false
            accompany_switch.isHidden = false
            songs_list_btn.isHidden = false
            for i in upper_key_down { i.isHidden = true }
            stop_record_replay_btn.isHidden = true
            record_btn.isHidden = false
        }
    }
    
    @IBAction func stop_following_btn(_ sender: Any) {
        if isFollowing == true {
            clearChannel()
            addGesture()
            isPlaying = true
            isFollowing = false
            follow_current_count = 0
            tap_change_for_following = 1
            last_following_array_count = 0
            count_for_compare = 0
            following_array_current_notes_amount = 0
            melody_array_for_following.removeAll()
            melody_array_for_compare.removeAll()
            thinking_head.isHidden = false
            thinking_loading.isHidden = false
            thinkint_bulb.isHidden = true
            following_btn.isHidden = true
            record_btn.isHidden = false
            accompany_switch.isEnabled = true
            song_name_label.isHidden = true
            accompany_isOn = true
            for i in upper_key_down { i.isHidden = true }
        }
    }
    
    @IBAction func start_switch_controller(_ sender: Any) {
        if accompany_switch.isOn == true {
            first_10_notes_array = create_first_10_notes_array()
            self.PianoDefaults.setValue(self.first_10_notes_array, forKey: "first_10")
            self.PianoDefaults.synchronize()
            accompany_isOn = true
            thinking_head.isHidden = false
            thinking_loading.isHidden = false
            setting_btn.isEnabled = false
            songs_list_btn.isEnabled = false
            record_btn.isEnabled = false
        } else {
            thinking_head.isHidden = true
            thinking_loading.isHidden = true
            thinkint_bulb.isHidden = true
            accompany_isOn = false
            setting_btn.isEnabled = true
            songs_list_btn.isEnabled = true
            record_btn.isEnabled = true
            record_btn.isHidden = false
            follow_current_count = 0
            tap_change_for_following = 1
            last_following_array_count = 0
            count_for_compare = 0
            following_array_current_notes_amount = 0
            melody_array_for_following.removeAll()
            melody_array_for_compare.removeAll()
            first_10_notes_array.removeAll()
        }
    }
    
    @IBAction func SongsList_btn(_ sender: Any) {
        isPlaying = false
    }
    
    @IBAction func Setting_btn(_ sender: Any) {
        isPlaying = false
    }
}

