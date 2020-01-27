//
//  SongsListViewController.swift
//  Digital_flute
//
//  Created by Christian Lin on 2019/1/28.
//  Copyright © 2019 Christian Lin. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class SongsListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    
    @IBOutlet weak var SongsListTableView: UITableView!
    
    //songs
    var songs: [NSManagedObject] = []
    var first_10_notes: [NSManagedObject] = []
    var songs_melody: [NSManagedObject] = []
    var songs_notes: [NSManagedObject] = []
    
    //player
    var replayers = [URL:AVAudioPlayer]()
    var duplicateReplayers = [AVAudioPlayer]()
    
    //replay number
    var PianoDefaults = UserDefaults.standard
    var replay_number = -1
    var replay_or_replace = 1
    
    //key
    let references = ["Piano.G3", "Piano.Ab3","Piano.A3", "Piano.Bb3","Piano.B3", "Piano.C4", "Piano.Db4","Piano.D4", "Piano.Eb4", "Piano.E4", "Piano.F4", "Piano.Gb4", "Piano.G4", "Piano.Ab4", "Piano.A4", "Piano.Bb4", "Piano.B4"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //register(_:forCellReuseIdentifier:) guarantees your table view will return a cell of the correct type when the Cell reuseIdentifier is provided to the dequeue method.
        SongsListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        //getting data from CoreData
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //get the current state of replay_or_replace
        if let buffer = PianoDefaults.object(forKey: "replay_or_replace") {
            replay_or_replace = buffer as! Int
        } else {
            replay_or_replace = 1
        }
        
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
                
        SongsListTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = songs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = song.value(forKeyPath: "song_name") as? String
        
        return cell
    }
    
    //delete particular song
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            managedContext.delete(self.songs[indexPath.row])
            managedContext.delete(self.songs_melody[indexPath.row])
            managedContext.delete(self.songs_notes[indexPath.row])
            managedContext.delete(self.first_10_notes[indexPath.row])
            
            
            do {
                try managedContext.save()
                songs.remove(at: indexPath.row)
                songs_melody.remove(at: indexPath.row)
                songs_notes.remove(at: indexPath.row)
                first_10_notes.remove(at: indexPath.row)
                SongsListTableView.reloadData()
            } catch {
                print("delete is fail")
            }
        }
    }
    
    //play the audio file  while tapping
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = songs[indexPath.row]
        print(song.value(forKeyPath: "song_name") as? String as Any)
        
        //after tapping the song in the core data, playing the key down image while replaying
        replay_number = indexPath.row
        PianoDefaults.set(replay_number, forKey: "replay_number")
        PianoDefaults.synchronize()
        
        performSegue(withIdentifier: "back_to_menu", sender: self)
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("deselect")
    }
    
    
    
    @IBAction func Cancel_btn(_ sender: Any) {
        SongsListTableView.reloadData()
    }
    

}

