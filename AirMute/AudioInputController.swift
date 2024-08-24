import AVFoundation

/// Configure an audio unit to have macOS allow AirPods to mute the mic.
/// No audio is recorded — the logic for it isn't in here, and permission is never requested.
internal final class AudioInputController {
    private var auHAL: AudioComponentInstance?
    private var inputBufferList: UnsafeMutableAudioBufferListPointer?
    private var sampleRate: Float = 0.0

    init?() {
        guard let audioDeviceID = getDefaultAudioDeviceID() else {
            assertionFailure()
            return nil
        }
        var osStatus: OSStatus = noErr

        // Create an AUHAL instance.
        var description = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_HALOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        guard let component = AudioComponentFindNext(nil, &description) else {
            assertionFailure()
            return
        }

        osStatus = AudioComponentInstanceNew(component, &auHAL)

        guard osStatus == noErr, let auHAL else {
            return nil
        }

        // Enable the input bus, and disable the output bus.
        let kInputElement: UInt32 = 1
        let kOutputElement: UInt32 = 0
        var kInputData: UInt32 = 1
        var kOutputData: UInt32 = 0
        let ioDataSize: UInt32 = UInt32(MemoryLayout<UInt32>.size)

        osStatus = AudioUnitSetProperty(
            auHAL,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Input,
            kInputElement,
            &kInputData,
            ioDataSize
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        osStatus = AudioUnitSetProperty(
            auHAL,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Output,
            kOutputElement,
            &kOutputData,
            ioDataSize
        )

        if osStatus != noErr {
            assertionFailure()
        }

        var inputDevice: AudioDeviceID = audioDeviceID
        let inputDeviceSize: UInt32 = UInt32(MemoryLayout<AudioDeviceID>.size)

        osStatus = AudioUnitSetProperty(
            auHAL,
            AudioUnitPropertyID(kAudioOutputUnitProperty_CurrentDevice),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &inputDevice,
            inputDeviceSize
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        // Adopt the stream format.
        var deviceFormat = AudioStreamBasicDescription()
        var desiredFormat = AudioStreamBasicDescription()
        var ioFormatSize: UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

        osStatus = AudioUnitGetProperty(
            auHAL,
            AudioUnitPropertyID(kAudioUnitProperty_StreamFormat),
            AudioUnitScope(kAudioUnitScope_Input),
            kInputElement,
            &deviceFormat,
            &ioFormatSize
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        osStatus = AudioUnitGetProperty(
            auHAL,
            AudioUnitPropertyID(kAudioUnitProperty_StreamFormat),
            AudioUnitScope(kAudioUnitScope_Output),
            kInputElement,
            &desiredFormat,
            &ioFormatSize
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        // Same sample rate, same number of channels.
        desiredFormat.mSampleRate = deviceFormat.mSampleRate
        desiredFormat.mChannelsPerFrame = deviceFormat.mChannelsPerFrame

        // Canonical audio format.
        desiredFormat.mFormatID = kAudioFormatLinearPCM
        desiredFormat
            .mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved
        desiredFormat.mFramesPerPacket = 1
        desiredFormat.mBytesPerFrame = UInt32(MemoryLayout<Float32>.size)
        desiredFormat.mBytesPerPacket = UInt32(MemoryLayout<Float32>.size)
        desiredFormat.mBitsPerChannel = 8 * UInt32(MemoryLayout<Float32>.size)

        osStatus = AudioUnitSetProperty(
            auHAL,
            AudioUnitPropertyID(kAudioUnitProperty_StreamFormat),
            AudioUnitScope(kAudioUnitScope_Output),
            kInputElement,
            &desiredFormat,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        // Store the format information.
        sampleRate = Float(desiredFormat.mSampleRate)

        // Get the buffer frame size.
        var bufferSizeFrames: UInt32 = 0
        var bufferSizeFramesSize = UInt32(MemoryLayout<UInt32>.size)

        osStatus = AudioUnitGetProperty(
            auHAL,
            AudioUnitPropertyID(kAudioDevicePropertyBufferFrameSize),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &bufferSizeFrames,
            &bufferSizeFramesSize
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        let bufferSizeBytes: UInt32 = bufferSizeFrames * UInt32(MemoryLayout<Float32>.size)
        let channels: UInt32 = deviceFormat.mChannelsPerFrame

        inputBufferList = AudioBufferList.allocate(maximumBuffers: Int(channels))
        for i in 0 ..< Int(channels) {
            inputBufferList?[i] = AudioBuffer(
                mNumberChannels: channels,
                mDataByteSize: UInt32(bufferSizeBytes),
                mData: malloc(Int(bufferSizeBytes))
            )
        }

        var callbackStruct = AURenderCallbackStruct(
            inputProc: { (
                inRefCon: UnsafeMutableRawPointer,
                ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                inTimeStamp: UnsafePointer<AudioTimeStamp>,
                inBusNumber: UInt32,
                inNumberFrame: UInt32,
                _: UnsafeMutablePointer<AudioBufferList>?
            ) -> OSStatus in

                let owner = Unmanaged<AudioInputController>.fromOpaque(inRefCon).takeUnretainedValue()
                owner.inputCallback(
                    ioActionFlags: ioActionFlags,
                    inTimeStamp: inTimeStamp,
                    inBusNumber: inBusNumber,
                    inNumberFrame: inNumberFrame
                )
                return noErr
            },
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )

        osStatus = AudioUnitSetProperty(
            auHAL,
            AudioUnitPropertyID(kAudioOutputUnitProperty_SetInputCallback),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &callbackStruct,
            UInt32(MemoryLayout<AURenderCallbackStruct>.size)
        )

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }

        osStatus = AudioUnitInitialize(auHAL)

        guard osStatus == noErr else {
            assertionFailure()
            return nil
        }
    }

    deinit {
        if let auHAL {
            AudioOutputUnitStop(auHAL)
            AudioComponentInstanceDispose(auHAL)
        }
        if let inputBufferList {
            for buffer in inputBufferList {
                free(buffer.mData)
            }
        }
    }

    private func inputCallback(
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrame: UInt32
    ) {
        guard let inputBufferList,
              let auHAL
        else {
            assertionFailure()
            return
        }

        let err = AudioUnitRender(
            auHAL,
            ioActionFlags,
            inTimeStamp,
            inBusNumber,
            inNumberFrame,
            inputBufferList.unsafeMutablePointer
        )
        guard err == noErr else {
            assertionFailure()
            return
        }
    }

    func start() {
        guard let auHAL else {
            assertionFailure()
            return
        }
        let status: OSStatus = AudioOutputUnitStart(auHAL)
        if status != noErr {
            assertionFailure()
        }
    }

    func stop() {
        guard let auHAL else {
            assertionFailure()
            return
        }
        let status: OSStatus = AudioOutputUnitStop(auHAL)
        if status != noErr {}
    }
}

private func getDefaultAudioDeviceID() -> AudioDeviceID? {
    var deviceID = AudioDeviceID()
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeInput,
        mElement: kAudioObjectPropertyElementMain
    )

    let status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        &dataSize,
        &deviceID
    )

    guard status == noErr else {
        assertionFailure()
        return nil
    }

    return deviceID
}
