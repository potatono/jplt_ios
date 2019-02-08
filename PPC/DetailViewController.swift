//
//  DetailViewController.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Firebase
import FirebaseStorage
import Photos


class DetailViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    enum State {
        case empty
        case recording
        case stopped
        case playing
        case paused
    }

    public var episode:Episode = Episode()
    
    private var _state:State = State.empty
    private var _audioRecorder:AVAudioRecorder!
    private let _recordSettings = [
        AVSampleRateKey:NSNumber(value: Float(44100.0)),
        AVFormatIDKey:NSNumber(value:Int32(kAudioFormatMPEG4AAC)),
        AVNumberOfChannelsKey:NSNumber(value: Int32(1)),
        AVEncoderAudioQualityKey:
            NSNumber(value: Int32(AVAudioQuality.medium.rawValue))
    ]
    private var _recordingSession:AVAudioSession!
    private var _timer: Timer!
    private var _audioPlayer:AVPlayer!
    private var _audioTimeObserverToken:Any?
    private var _editable:Bool = true

    // MARK: Properties
    @IBOutlet weak var vuMeter: UIVUMeter!
    @IBOutlet weak var mediaButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var coverButton: UIButton!
    @IBOutlet weak var scrubSlider: UISlider!
    @IBOutlet weak var scrubAtLabel: UILabel!
    @IBOutlet weak var scrubRemainLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    // MARK: Actions
    @IBAction func didPressMedia(_ sender: Any) {
        switch _state {
        case .empty:
            startRecording()
        case .recording:
            stopRecording()
        case .stopped:
            startPlayback()
        case .playing:
            pausePlayback()
        case .paused:
            resumePlayback()
        }
    }
    
    @IBAction func scrubSliderChanged(_ sender: Any) {
        let time = CMTime(seconds: Double(scrubSlider.value), preferredTimescale: 1)
        
        _audioPlayer.seek(to: time)
    }
    
    @IBAction func scrubSliderDidStart(_ sender: Any) {
        if _state == .playing {
            _audioPlayer.pause()
        }
    }
    
    @IBAction func scrubSliderDidEnd(_ sender: Any) {
        print(_state)
        if _state == .playing {
            _audioPlayer.play()
        }
    }
    
    @IBAction func didPressDelete(_ sender: Any) {
        let refreshAlert = UIAlertController(title: "Delete Episode", message: "Are you sure?",
                                             preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Deleting episode..")
            self.episode.delete() { () in
                self.performSegue(withIdentifier: "unwindDetailSegue", sender: self)
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Delete cancelled")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func didPressCover(_ sender: Any) {
        choosePhoto()
    }
    
    @IBAction func didBeginEditingTitle(_ sender: Any) {
        self.view.frame.origin.y = -128
    }
    
    @IBAction func didEndEditingTitle(_ sender: Any) {
        self.view.frame.origin.y = 0
    }
    
    @IBAction func didEditTitle(_ sender: Any) {
        episode.title = titleTextField.text ?? "New Episode"
        episode.save()
    }
    
    @IBAction func doneEditingTitle(_ sender: Any) {
        titleTextField.resignFirstResponder()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.text = episode.title
        coverButton.setImage(episode.cover, for: UIControl.State.normal)
        coverButton.setImage(episode.cover, for: UIControl.State.disabled)
        
        _editable = episode.canEdit()
        titleTextField.isEnabled = _editable
        coverButton.isEnabled = _editable
        deleteButton.isEnabled = _editable
        
        if episode.remoteURL != nil {
            setState(.stopped)
            scrubSlider.isEnabled = true
        }
        else {
            mediaButton.isEnabled = _editable
        }
    }
    
    // MARK: Methods
    func setState(_ value:State) {
        _state = value
        var image_name:String?
        
        switch _state {
        case .empty:
            image_name = "media_record"
        case .recording:
            image_name = "media_stop"
        case .stopped:
            image_name = "media_play"
        case .playing:
            image_name = "media_pause"
        case .paused:
            image_name = "media_play"
            
        }

        mediaButton.setImage(UIImage(named: image_name!), for: UIControl.State.normal)
    }
    
    func ensurePhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("Photo access is authorized")
        case .denied, .restricted :
            print("Photo access is denied or restricted")
        case .notDetermined:
            print("Asking for permissions to photos")
            
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    print("Photo access was granted")
                case .denied, .restricted:
                    print("Photo access was denied or restricted")
                case .notDetermined:
                    print("Photo access still not determined")
                }
            }
        }
    }
    
    func choosePhoto() {
        ensurePhotoPermission()
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = (self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!)
    {
        self.dismiss(animated: true, completion: { () -> Void in
            print("Dismissed")
        })
        
        print("Setting image")
        
        episode.cover = image
        coverButton.setImage(image, for:UIControl.State.normal)
        episode.uploadCover()
    }
    
    func ensureRecorder() {
        if _audioRecorder == nil {
            setupRecorder()
            setupVuMeter()
        }
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
            
            try _audioRecorder = AVAudioRecorder(url: episode.localURL,
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

    @objc func updateVuMeter() {
        if (_audioRecorder.isRecording) {
            _audioRecorder.updateMeters()
            vuMeter.addSample(sample: _audioRecorder.averagePower(forChannel: 0))
            scrubRemainLabel.text = "-" + formatTime(_audioRecorder.currentTime)
        }
    }

    func startRecording() {
        ensureRecorder()
        
        print("Starting recording..")
        vuMeter.isHidden = false
        _audioRecorder.record()
        setState(.recording)
    }

    func stopRecording() {
        print("Stopping recording..")
        
        _audioRecorder.stop()
        episode.uploadRecording()
        
        vuMeter.isHidden = true
        scrubSlider.isEnabled = true
        
        setState(.stopped)
    }
    
    
    func formatTime(_ time:CMTime) -> String {
        return formatTime(time.seconds)
    }
    
    func formatTime(_ seconds:Double) -> String {
        let minutes = Int(seconds / 60)
        let seconds = Int(seconds) % 60
        
        return String(format:"%d:%02d", minutes, seconds)
    }
    
    func setupPlayer() {
        let session = AVAudioSession.sharedInstance()
        
        do {
        try session.setCategory(.playback,
                                mode: AVAudioSession.Mode.default,
                                options: AVAudioSession.CategoryOptions.defaultToSpeaker
            )
        }
        catch _ {}
        
        _audioPlayer = AVPlayer(url: episode.getPlaybackURL()!)
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.1, preferredTimescale: timeScale)

        _audioTimeObserverToken = _audioPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) {
            [weak self] time in
            
            let total = self!._audioPlayer.currentItem!.asset.duration
            let total_sec = CMTimeGetSeconds(total)
            let time_sec = CMTimeGetSeconds(time)
            let remain = total - time
            
            self!.scrubSlider.maximumValue = Float(total_sec)
            self!.scrubSlider.value = Float(time_sec)
            
            self!.scrubAtLabel.text = self!.formatTime(time)
            self!.scrubRemainLabel.text = "-" + self!.formatTime(remain)
            
            if time == total {
                self!.resetPlayback()
            }
        }
    }
    
    func ensurePlayer() {
        if _audioPlayer == nil {
            setupPlayer()
        }
    }
    
    func startPlayback() {
        ensurePlayer()
        
        _audioPlayer.play()
        setState(.playing)
    }
    
    func pausePlayback() {
        _audioPlayer.pause()
        setState(.paused)
    }
    
    func resumePlayback() {
        _audioPlayer.play()
        setState(.playing)
    }
    
    func resetPlayback() {
        _audioPlayer.seek(to: CMTime(value:0, timescale:1))
        setState(.stopped)
    }
}

