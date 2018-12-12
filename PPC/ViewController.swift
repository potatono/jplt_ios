//
//  ViewController.swift
//  PPC
//
//  Created by Justin Day on 11/5/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseStorage

class ViewController: UIViewController {
    var _audioRecorder : AVAudioRecorder!
    let _recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0)),
        AVFormatIDKey : NSNumber(value:Int32(kAudioFormatMPEG4AAC)),
        AVNumberOfChannelsKey : NSNumber(value: Int32(1)),
        AVEncoderAudioQualityKey :
            NSNumber(value: Int32(AVAudioQuality.medium.rawValue))
    ]
    var _recordingSession: AVAudioSession!
    var _timer: Timer!
    var _user:User!

    // MARK: Properties
    @IBOutlet weak var recordButton: UIBarButtonItem!
    @IBOutlet weak var vuMeter: UIVUMeter!
    
    // MARK: Actions
    @IBAction func unwindAuth(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func record(_ sender: Any) {
        if _audioRecorder.isRecording {
            print("Stopping recording..")
            recordButton.title = "Record"
            _audioRecorder.stop()
            send()
        }
        else {
            print("Starting recording..")
            recordButton.title = "Stop"
            _audioRecorder.record()
        }
    }

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setupRecorder()
        //setupVuMeter()
    }

    override func viewDidAppear(_ animated: Bool) {
        ensureUser()
    }

    // MARK: Methods
    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent("sound.m4a")
        return soundURL
    }
    
    func setupRecorder() {
        _recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try _recordingSession.setCategory(.playAndRecord, mode: .default)
            try _recordingSession.setActive(true)
            _recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        // Success
                    } else {
                        // failed to record!
                    }
                }
            }
            
            try _audioRecorder = AVAudioRecorder(url: directoryURL()!,
                                                settings: _recordSettings)
            _audioRecorder.prepareToRecord()
            _audioRecorder.isMeteringEnabled = true
        }
        catch {}
    }
    
    func setupVuMeter() {
        _timer = Timer.scheduledTimer(timeInterval: 1/32.0,
                                     target: self,
                                     selector: (#selector(updateVuMeter)),
                                     userInfo: nil, repeats: true)
    }

    func ensureUser() {
        if let user = Auth.auth().currentUser {
            print("[AUTH] User is", user.uid)
            print("[AUTH] User phone is", user.phoneNumber as Any)
        }
        else {
            print("[AUTH] No user")
            self.performSegue(withIdentifier: "authPhoneSegue", sender: self)
        }
    }
    
    @objc func updateVuMeter() {
        if (_audioRecorder.isRecording) {
            _audioRecorder.updateMeters()
            vuMeter.addSample(sample: _audioRecorder.averagePower(forChannel: 0))
        }
    }
    
    func send() {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child("eps/sound.m4a")
        let localFile = directoryURL()
        
        print("Uploading file..")
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = fileRef.putFile(from: localFile!, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            print("Uploaded " + String(size) + " bytes")
        }
    }
}

