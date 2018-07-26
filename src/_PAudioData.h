//
//  PAudioData.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/25.
//

#ifndef PAudioData_h
#define PAudioData_h

class PAudioData{
    
//    AudioBufferList convertedData;
//    ExtAudioFileRef fileRef;
    int msample;
    NSMutableData *sampleData;
    int maxSample;
    
    ofFbo _fbo;
    
public:
    PAudioData(){}
    PAudioData(string file_){
        loadFile(file_);
    }
    void loadFile(string file_){
        
        
        NSString *name=[[NSString alloc] initWithUTF8String:file_.c_str()]; //YOUR FILE NAME
        NSURL *url=[[NSBundle mainBundle] URLForResource:name withExtension:@"wav"];
        
        
        NSError *error;
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
        BOOL success = (assetReader != nil);
        
        
        if (!assetReader) {
            NSLog(@"Error creating asset reader: %@", [error localizedDescription]);
            return;
        }
        
        AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        NSDictionary *outputSettings = @{
                                         AVFormatIDKey               : @(kAudioFormatLinearPCM),
                                         AVLinearPCMIsBigEndianKey   : @NO,
                                         AVLinearPCMIsFloatKey       : @NO,
                                         AVLinearPCMBitDepthKey      : @(16)
                                         };
        
        AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:outputSettings];
        [assetReader addOutput:trackOutput];
        [assetReader startReading];
        
        sampleData=[NSMutableData data];
        
        
        while (assetReader.status == AVAssetReaderStatusReading) {
            
            CMSampleBufferRef sampleBuffer = [trackOutput copyNextSampleBuffer];
            
            if (sampleBuffer) {
                CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
                size_t length = CMBlockBufferGetDataLength(blockBufferRef);
                SInt16 sampleBytes[length];
                CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes);
                [sampleData appendBytes:sampleBytes length:length];
                
                CMSampleBufferInvalidate(sampleBuffer);
                CFRelease(sampleBuffer);
            }
        }
        
        if (assetReader.status == AVAssetReaderStatusCompleted) {
            
             msample=[sampleData length];
             NSLog(@"Read %d audio samples",msample);
            
            generateSpectrum();
            
      //      return sampleData;
        } else {
            NSLog(@"Failed to read audio samples from asset");
       //     return nil;
        }
        
        
//        const char *cString=[source cStringUsingEncoding:NSASCIIStringEncoding];
//
//        CFStringRef str = CFStringCreateWithCString(
//                                                    NULL,
//                                                    cString,
//                                                    kCFStringEncodingMacRoman
//                                                    );
//        CFURLRef inputFileURL = CFURLCreateWithFileSystemPath(
//                                                              kCFAllocatorDefault,
//                                                              str,
//                                                              kCFURLPOSIXPathStyle,
//                                                              false
//                                                              );
//
//        //ExtAudioFileRef fileRef;
//        ExtAudioFileOpenURL(inputFileURL, &fileRef);
//
//
//        AudioStreamBasicDescription audioFormat;
//        audioFormat.mSampleRate = 44100;   // GIVE YOUR SAMPLING RATE
//        audioFormat.mFormatID = kAudioFormatLinearPCM;
//        audioFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
//        audioFormat.mBitsPerChannel = sizeof(Float32) * 8;
//        audioFormat.mChannelsPerFrame = 1; // Mono
//        audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * sizeof(Float32);  // == sizeof(Float32)
//        audioFormat.mFramesPerPacket = 1;
//        audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame; // = sizeof(Float32)
//
//        // 3) Apply audio format to the Extended Audio File
//        ExtAudioFileSetProperty(
//                                fileRef,
//                                kExtAudioFileProperty_ClientDataFormat,
//                                sizeof (AudioStreamBasicDescription), //= audioFormat
//                                &audioFormat);
//
//        numSamples = 1024; //How many samples to read in at a time
//        UInt32 sizePerPacket = audioFormat.mBytesPerPacket; // = sizeof(Float32) = 32bytes
//        UInt32 packetsPerBuffer = numSamples;
//        UInt32 outputBufferSize = packetsPerBuffer * sizePerPacket;
//
//        // So the lvalue of outputBuffer is the memory location where we have reserved space
//        UInt8 *outputBuffer = (UInt8 *)malloc(sizeof(UInt8 *) * outputBufferSize);
//
//
//
////        AudioBufferList convertedData ;//= malloc(sizeof(convertedData));
//
//        convertedData.mNumberBuffers = 1;    // Set this to 1 for mono
//        convertedData.mBuffers[0].mNumberChannels = audioFormat.mChannelsPerFrame;  //also = 1
//        convertedData.mBuffers[0].mDataByteSize = outputBufferSize;
//        convertedData.mBuffers[0].mData = outputBuffer; //


    }
    float readData(float pos_){
        
        int index_=floor(pos_*msample);
        float val=(float)((SInt16*)sampleData)[index_];
        cout<<pos_<<": "<<val<<endl;
        
        return val;
        
//        UInt32 frameCount = numSamples;
//        float *samplesAsCArray;
////        int j =0;
////        double floatDataArray[numSamples]   ; // SPECIFY YOUR DATA LIMIT MINE WAS 882000 , SHOULD BE EQUAL TO OR MORE THAN DATA LIMIT
//        float sum=0;
////        while (frameCount > 0){
//            ExtAudioFileRead(
//                             fileRef,
//                             &frameCount,
//                             &convertedData
//                             );
//            if (frameCount > 0)  {
//                AudioBuffer audioBuffer = convertedData.mBuffers[0];
//                samplesAsCArray = (float *)audioBuffer.mData; // CAST YOUR mData INTO FLOAT
//                //return (float)samplesAsCArray[0];
//                for (int i =0; i<1024 /*numSamples */; i++) { //YOU CAN PUT numSamples INTEAD OF 1024
////
////                    floatDataArray[j] = (double)samplesAsCArray[i] ; //PUT YOUR DATA INTO FLOAT ARRAY
////                    if(i==0)
////                        cout<<"frame= "<<frameCount<<" - "<<floatDataArray[j]<<endl;  //PRINT YOUR ARRAY'S DATA IN FLOAT FORM RANGING -1 TO +1
////                    j++;
////
////
//                    float tmp=samplesAsCArray[0];
//                    sum+=tmp*tmp;
//                }
//            }
//        return sum;
//        }
    }
    void generateSpectrum(){
        
        _fbo.allocate(ofGetWidth(),ofGetHeight(),GL_RGB);
        _fbo.begin();
        float step=1024;
        float wid=(float)ofGetHeight()/msample/step;
        ofPushStyle();
        ofSetColor(255);
        for(float i=0;i<msample;i+=step){
            float val=(float)((SInt16*)sampleData)[(int)i];
            //ofLog()<<val;
            ofDrawRectangle(0,i*wid,wid,ofGetWidth()*(float)val/1000.0);
        }
        ofPopStyle();
        _fbo.end();
    }
    
    void draw(){
        _fbo.draw(0,0);
    }
};


#endif /* PAudioData_h */
