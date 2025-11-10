//
//  SoundManager.swift
//  HiPixel
//
//  Created by 十里 on 2025/11/10.
//

import AppKit

class SoundManager {
    static let shared = SoundManager()
    private var sound: NSSound?
    private var soundName: String?
    private var soundVolume: Float = 1.0

    private init() {}

    func loadSound(named name: String, volume: Float = 1.0) {
        if sound != nil && soundName == name && soundVolume == volume {
            return
        }

        if sound != nil {
            sound?.stop()
            sound = nil
            soundName = nil
        }
      
        guard let newSound = NSSound(named: name) else {
            print("Sound not loaded. Please load it first.")
            return
        }

        newSound.volume = volume
        sound = newSound
        soundName = name
        soundVolume = volume
    }

    func playSound() {
        guard let sound = sound else {
            print("Sound not loaded. Please load it first.")
            return
        }
        
        // Stop current playback and restart immediately
        sound.stop()
        sound.currentTime = 0
        sound.play()
    }
}
