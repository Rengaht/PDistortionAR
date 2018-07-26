//
//  PAudioData.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/25.
//

#ifndef PAudioData_h
#define PAudioData_h

#define noiseFloor (-50.0)

#include "SCWaveformCache.h"

class PAudioData{
    
//    AudioBufferList convertedData;
//    ExtAudioFileRef fileRef;
//    int msample;
//    NSMutableData *sampleData;
//    int maxSample;
    
    ofFbo _fbo;
    
    SCWaveformCache *_cache;
    NSMutableArray *_waveforms;
    float _duration;
    
public:
    PAudioData(){}
    PAudioData(string file_){
        loadFile(file_);
    }
    void loadFile(string file_){
        
        NSString *name=[[NSString alloc] initWithUTF8String:file_.c_str()]; //YOUR FILE NAME
        NSURL *url=[[NSBundle mainBundle] URLForResource:name withExtension:@"wav"];
        _cache=[SCWaveformCache new];
        _cache.asset=[AVURLAsset URLAssetWithURL:url options:nil];
        CMTime assetDuration = [_cache actualAssetDuration];
        _duration=CMTimeGetSeconds(assetDuration);
        ofLog()<<"read wavefile "<<file_<<" duration= "<<_duration;
        NSError *error = nil;
        [_cache readTimeRange:CMTimeRangeMake(CMTimeMake(0,20),CMTimeMake(_duration*20,20)) width:floor(_duration*30) error:&error];

        generateSpectrum();
    }
    float readData(float pos_){
        
        CMTime timestart=CMTimeMake(pos_/1000.0*20,20);
        float val_=[_cache readPoint:timestart];
        
        float v_=(val_==-INFINITY)?0:1-abs(val_)/60.0;
        //float v_=pow(10,val_/60.0);
        
        //ofLog()<<pos_<<" "<<v_;
        return v_;

    }
    void generateSpectrum(){
        
        _fbo.allocate(ofGetWidth(),ofGetHeight(),GL_RGB);
        _fbo.begin();
        ofSetBackgroundColor(0,0,255);
        float step=1;
        int msample=_duration;
        float wid=ofGetHeight()/(float)msample;
        ofPushStyle();
        ofSetColor(255);
        for(float i=0;i<msample;i+=step){
            float val=[_cache readPoint:CMTimeMake(i*20,20)];
//            ofLog()<<val;
            ofDrawRectangle(0,i*wid,abs((float)val),wid);
        }
        ofPopStyle();
        _fbo.end();
    }
    
    void draw(float pos_){
        
        _fbo.begin();
        int msample=_duration;
        float wid=ofGetHeight()/(float)msample;
        ofPushStyle();
        ofSetColor(255,0,0);
        
        float val=[_cache readPoint:CMTimeMake(pos_/1000.0*20,20)];
        ofDrawRectangle(abs((float)val),pos_/1000.0*wid,ofGetWidth()-abs((float)val),wid);
        
        ofPopStyle();
        _fbo.end();
        
        _fbo.draw(0,0);
        
    }
};


#endif /* PAudioData_h */
