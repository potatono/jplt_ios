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
import LinkPresentation


class DetailViewController: ImagePickerViewController, UIActivityItemSource {
    enum State {
        case empty
        case recording
        case stopped
        case playing
        case paused
    }
    
    enum MetaState {
        case new
        case recorded
        case editing
        case published
        case locked
    }

    public var podcast:Podcast = Podcast()
    public var episode:Episode = Episode()
    
    private var _state:State = State.empty
    private var _metaState:MetaState = MetaState.new
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
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var coverButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var publishButton: UIBarButtonItem!
    @IBOutlet weak var tapToChangeCoverLabel: UILabel!
    @IBOutlet weak var crosspostButton: UIButton!
    
    
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
        
        _audioPlayer?.seek(to: time)
    }
    
    @IBAction func scrubSliderDidStart(_ sender: Any) {
        if _state == .playing {
            _audioPlayer?.pause()
        }
    }
    
    @IBAction func scrubSliderDidEnd(_ sender: Any) {
        if _state == .playing {
            _audioPlayer?.play()
            
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
        presentImagePicker(from: sender)
    }
    
    @IBAction func didBeginEditingTitle(_ sender: Any) {
        //self.view.frame.origin.y = -128
        //titleTextField.borderStyle = .roundedRect
    }
    
    @IBAction func didEndEditingTitle(_ sender: Any) {
        //self.view.frame.origin.y = 0
        //titleTextField.borderStyle = .none

    }
    
    @IBAction func didEditTitle(_ sender: Any) {
        
    }
    
    @IBAction func doneEditingTitle(_ sender: Any) {
        if titleTextField.text != nil && titleTextField.text!.count > 0 {
            episode.title = titleTextField.text!
            episode.save()
        }
        else {
            titleTextField.text = episode.title
        }
        
        titleTextField.resignFirstResponder()
    }
    
    @IBAction func didPressPublish(_ sender: Any) {
        print("Published Button Pressed")
        switch _metaState {
        case .published:
            setMetaState(.editing)
        case .editing:
            setMetaState(.published)
        case .recorded:
            episode.publish(podcast: podcast)
            setMetaState(.published)
        case .new:
            print("Publish pressed in .new _metaState, this shouldn't happen.")
        case .locked:
            print("Publish pressed in .locked _metaState, this shouldn't happen.")
        }
    }
    
    @IBAction func didPressShare(_ sender: Any) {
        let alertController = UIAlertController(title: "Share Episode", message: nil, preferredStyle: .actionSheet)

        let crosspostButton = UIAlertAction(title: "Crosspost to..", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: "crosspostSegue", sender: sender)
        })
        alertController.addAction(crosspostButton)

        let shareButton = UIAlertAction(title: "Share via..", style: .default, handler: { (action) -> Void in
            let activityViewController : UIActivityViewController = UIActivityViewController(
                activityItems: [self], applicationActivities: nil)

            // This lines is for the popover you need to show in iPad
            activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)

            // Anything you want to exclude
            activityViewController.excludedActivityTypes = [
                UIActivity.ActivityType.postToWeibo,
                UIActivity.ActivityType.print,
                UIActivity.ActivityType.assignToContact,
                UIActivity.ActivityType.saveToCameraRoll,
                UIActivity.ActivityType.addToReadingList,
                UIActivity.ActivityType.postToFlickr,
                UIActivity.ActivityType.postToVimeo,
                UIActivity.ActivityType.postToTencentWeibo
            ]

            self.present(activityViewController, animated: true, completion: nil)
        })
        alertController.addAction(shareButton)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
        })
        alertController.addAction(cancelButton)

        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    func getShareURL() -> URL {
        let pid = Util.shortenId(self.podcast.pid)
        let eid = Util.shortenId(self.episode.id)
        let url = URL(string: "https://jplt.com/play/\(pid)/\(eid)")!
        return url
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return getShareURL()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return getShareURL()
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let image = self.coverButton.image(for: .normal)!
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.iconProvider = imageProvider
        metadata.url = getShareURL()
        metadata.title = episode.title
        
        return metadata
    }

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutControls()

        episode.addBinding(forTopic: "title", control: titleTextField)
        episode.addBinding(forTopic: "remoteCoverURL", control: coverButton)
        episode.addBinding(forTopic: "createDate", control: dateLabel)
        episode.profile.addBinding(forTopic: "username", control: usernameLabel)
        episode.profile.addBinding(forTopic: "remoteThumbURL", control: profileImageView)

        if episode.remoteURL != nil {
            setState(.stopped)
            scrubSlider.isEnabled = true
        }
        else {
            mediaButton.isEnabled = episode.canEdit()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        tapToChangeCoverLabel.layer.cornerRadius = 5
        tapToChangeCoverLabel.layer.masksToBounds = true
        
        determineMetaState()
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
         self.view.frame.origin.y = -150 // Move view 150 points upward
    }

    @objc func keyboardWillHide(_ sender: Notification) {
         self.view.frame.origin.y = 0 // Move view to original position
    }
    
    func layoutControls() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height
        
        let size = screenHeight / 2
        print("Resizing coverButton to \(size)")
        
        coverButtonWidthConstraint.constant = size
        coverButtonHeightConstraint.constant = size
        coverButton.layoutIfNeeded()
        titleTextField.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        episode.removeBinding(titleTextField)
        episode.removeBinding(coverButton)
        episode.removeBinding(dateLabel)
        episode.profile.removeBinding(usernameLabel)
        episode.profile.removeBinding(profileImageView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let crosspostTableViewController = segue.destination as? CrosspostTableViewController {
            let pids = Profiles.me().subscriptions.drop(while: { $0 == podcast.pid })
            crosspostTableViewController.podcasts = pids.map({ return Podcast($0) })
            crosspostTableViewController.episode = episode
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
    
    func setMetaState(_ value:MetaState) {
        print("MetaState set to \(value)")
        _metaState = value
        
        setupMetaControls()
    }
    
    func determineMetaState() {
        if episode.canEdit() {
            if episode.published {
                setMetaState(.published)
            }
            else if episode.remoteURL != nil {
                setMetaState(.recorded)
            }
            else {
                setMetaState(.new)
            }
        }
        else {
            setMetaState(.locked)
        }
    }
    
    func setupMetaControls() {
        switch _metaState {
        case .new:
            tapToChangeCoverLabel.isHidden = false
            publishButton.title = "Publish"
            publishButton.isEnabled = false
            titleTextField.borderStyle = .roundedRect
            titleTextField.isEnabled = true
            coverButton.isEnabled = true
            deleteButton.isHidden = false
            crosspostButton.isHidden = false
            crosspostButton.isEnabled = false
            scrubSlider.isHidden = true
            scrubAtLabel.isHidden = true
            view.constraint(withIdentifier: "scrubremain-align-right")?.priority = .defaultLow
            view.constraint(withIdentifier: "scrubremain-center")?.priority = .required
            
        case .recorded:
            tapToChangeCoverLabel.isHidden = false
            publishButton.title = "Publish"
            publishButton.isEnabled = true
            titleTextField.borderStyle = .roundedRect
            titleTextField.isEnabled = true
            coverButton.isEnabled = true
            deleteButton.isHidden = false
            crosspostButton.isHidden = false
            crosspostButton.isEnabled = false
            scrubSlider.isHidden = false
            scrubAtLabel.isHidden = false
            view.constraint(withIdentifier: "scrubremain-align-right")?.priority = .required
            view.constraint(withIdentifier: "scrubremain-center")?.priority = .defaultLow

        case .editing:
            tapToChangeCoverLabel.isHidden = false
            publishButton.title = "Done"
            publishButton.isEnabled = true
            titleTextField.borderStyle = .roundedRect
            titleTextField.isEnabled = true
            coverButton.isEnabled = true
            deleteButton.isHidden = false
            crosspostButton.isHidden = false
            crosspostButton.isEnabled = true
            scrubSlider.isHidden = false
            scrubAtLabel.isHidden = false
            view.constraint(withIdentifier: "scrubremain-align-right")?.priority = .required
            view.constraint(withIdentifier: "scrubremain-center")?.priority = .defaultLow

        case .published:
            tapToChangeCoverLabel.isHidden = true
            publishButton.title = "Edit"
            publishButton.isEnabled = true
            titleTextField.borderStyle = .none
            titleTextField.isEnabled = false
            coverButton.isEnabled = false
            deleteButton.isHidden = false
            crosspostButton.isHidden = false
            crosspostButton.isEnabled = true
            scrubSlider.isHidden = false
            scrubAtLabel.isHidden = false
            view.constraint(withIdentifier: "scrubremain-align-right")?.priority = .required
            view.constraint(withIdentifier: "scrubremain-center")?.priority = .defaultLow

        case .locked:
            tapToChangeCoverLabel.isHidden = true
            publishButton.title = ""
            publishButton.isEnabled = false
            titleTextField.borderStyle = .none
            titleTextField.isEnabled = false
            coverButton.isEnabled = false
            deleteButton.isHidden = true
            crosspostButton.isHidden = true
            scrubSlider.isHidden = false
            scrubAtLabel.isHidden = false
            view.constraint(withIdentifier: "scrubremain-align-right")?.priority = .required
            view.constraint(withIdentifier: "scrubremain-center")?.priority = .defaultLow
        }
        
    }
        
    override func didPickImage(image: UIImage) {
        print("Setting image")
        self.view.makeToastActivity(.center)
        
        coverButton.setImage(image, for:UIControl.State.normal)
        coverButton.setImage(image, for:UIControl.State.disabled)
        episode.uploadCover(image) {
            self.view.hideToastActivity()
        }
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
            _recordingSession.requestRecordPermission() { _ in /*[unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        // Success
                    } else {
                        // failed to record!
                    }
                }*/
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
        
        self.view.makeToastActivity(.center)
        _audioRecorder.stop()
        episode.uploadRecording() {
            self.setMetaState(.recorded)
            self.view.hideToastActivity()
        }
        
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
            try session.setCategory(
                .playback,
                mode: AVAudioSession.Mode.default,
                options: [ .mixWithOthers, .allowAirPlay, .defaultToSpeaker ]
            )
            
            try session.setActive(true)
        }
        catch {
            print(error)
        }
        
        _audioPlayer = AVPlayer(url: episode.getPlaybackURL()!)
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.1, preferredTimescale: timeScale)

        _audioTimeObserverToken = _audioPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) {
            [weak self] time in
            
            if let self = self {
                let total = self._audioPlayer.currentItem!.asset.duration
                let total_sec = CMTimeGetSeconds(total)
                let time_sec = CMTimeGetSeconds(time)
                let remain = total - time
                
                self.view.hideToastActivity()
                self.scrubSlider.maximumValue = Float(total_sec)
                self.scrubSlider.value = Float(time_sec)
                
                self.scrubAtLabel.text = self.formatTime(time)
                self.scrubRemainLabel.text = "-" + self.formatTime(remain)
                
                if time == total {
                    self.resetPlayback()
                }
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
        
        self.view.makeToastActivity(.center)
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

