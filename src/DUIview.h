//
//  DUIview.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/24.
//

#ifndef DUIview_h
#define DUIview_h


class DUIView{
    
    float _wid;
//    float _hei;
    ofImage _img_play,_img_pause;
    
    int _duration;
    ofTrueTypeFont font;
    float _due_offset_x;
    float _due_offset_y;
    
    string _duration_string;
    ofRectangle _bound;
    
    string _play_string;
    ofRectangle _play_bound;
    
    string _hint;
    
    bool _debug;
    float _margin;
    
public:
    
    bool _playing;
    bool _bad_tracking;
    
    ofEvent<int> _event_play;
    ofEvent<int> _event_time;
    
    DUIView(int due_){
        
        _margin=5;
        _debug=true;
        
        _duration=due_;
        _wid=ofGetWidth()/40;
        _img_play.load("play-button.png");
        _img_pause.load("pause-button.png");
        
        int fontSize=8;//_wid/4;
        if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice())
            fontSize*=2;
        
        //font.load("fonts/mono0755.ttf", fontSize,true, false, true, 0.4, 72);
        font.load("fonts/mono0755.ttf", fontSize);
        _duration_string="/"+getTimeString(_duration);
        string tmp=getTimeString(_duration)+_duration_string;
        auto rec=font.getStringBoundingBox(tmp,0,0);
        _due_offset_x=rec.width;
        _due_offset_y=rec.height;
        
        _bound=ofRectangle(0,ofGetHeight()-_due_offset_y,ofGetWidth(),_due_offset_y);
        setPlay(false);
     
        
    }
    void draw(int time_){
       
        
        
        /* play & pause */
        ofPushMatrix();
        ofTranslate(_play_bound.x,_play_bound.y+_play_bound.height);
        
        ofPushStyle();
        ofSetColor(255);
        font.drawString(_play_string,0,0);
        
        ofPopStyle();
        
        ofPopMatrix();
        
        
        ofPushMatrix();
        ofTranslate(_bound.x,_bound.y);
        
        
//        if(_playing) _img_play.draw(ww/2-_wid/2,0,_wid,_wid);
//        else _img_pause.draw(ww/2-_wid/2,0,_wid,_wid);

        /* timeline */
        float ww=ofGetWidth();
        
        ofPushStyle();
        
        ofSetColor(255);
//        ofDrawRectangle(0,0,_bound.width,_bound.height/2);
        
        font.drawString(getTimeString(time_)+_duration_string,ww-_due_offset_x-_margin,0);
        
//        ofSetColor(120);
//        ofDrawRectangle(0,0,ofMap(time_,0,_duration,0,_bound.width),_bound.height/2);
        
        ofPopStyle();
        
        
        ofPopMatrix();
        
        
        
        
        /* hint */
        ofRectangle rec_=font.getStringBoundingBox(_hint,0,0);
        font.drawString(_hint,ww/2-rec_.width/2, ofGetHeight()/2-rec_.height/2);
        
        
        if(!_debug) return;
        
        // ========== DEBUG STUFF ============= //
            int p = ofGetHeight() * 0.035;
        
        //    font.drawString("stage       = " + ofToString(_stage),    x, y+=p);
            font.drawString(ofToString(ofGetFrameRate()),p/2,p);
        //    font.drawString(ofToString( ofGetFrameRate() ),p/2,p*2);
        //    font.drawString("state       = " + ofToString(processor->camera->getTrackingState()),x, y+=p);
        
        
        //    font.drawString("#feature obj= " + ofToString(_feature_object.size()),x, y+=p);
        //    font.drawString("#static obj = " + ofToString(_static_object.size()),x, y+=p);
        //    font.drawString("#record obj = " + ofToString(_record_object.size()),x, y+=p);
        
        //font.drawString("#point cloud= " + ofToString(processor->pointCloud.getNumFeatures()),x, y+=p);
        //font.drawString("#plane      = " + ofToString(processor->anchorController->getNumPlanes()),x, y+=p);
        //font.drawString("#anchor     = " + ofToString(processor->anchorController->getNumAnchors()),x, y+=p);

        
//        ofPushStyle();
//        ofSetColor(255,0,0);
//        ofNoFill();
//
//        //ofDrawRectangle(_bound);
//        ofDrawRectangle(_play_bound);
//
//        ofPopStyle();
//

    }
    string getTimeString(int time_){
        return formatString("%02d",floor(time_/60000))+":"+formatString("%02d",floor((time_/1000)%60));//+":"+formatString("%02d",floor(time_%1000/10));
    }
    string formatString(string format, int number) {
        char buffer[100];
        sprintf(buffer, format.c_str(), number);
        return (string)buffer;
    }
    void setHint(int stage_){
        
       
        if(!_playing){
            AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
            for(AVAudioSessionPortDescription* desc in [route outputs]){
                if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) _hint="";
                else _hint="BEST WITH HEADPHONE";
            }
                //_hint="BEST WITH HEADPHONE";
        }else{
            
            if(_bad_tracking){
                _hint="!!! Bad Tracking State !!!";
                return;
            }else{
            
                switch(stage_){
                    case 0:
                        _hint="WAIT";
                        break;
                    case 1:
                        _hint="WATCH";
                        break;
                    case 2:
                        _hint="TOUCH & MOVE";
                        break;
                    case 3:
                    case 4:
                        _hint="FOLLOW";
                        break;
                    case 5:
                    case 6:
                        _hint="STAY";
                        break;
                }
            }
        }
        if(_hint.length()>0){
            if(ofGetFrameNum()%120<60) _hint="////// "+_hint+" //////";
            else _hint="\\\\\\\\\\\\ "+_hint+" \\\\\\\\\\\\";
        }
        
        if(!_playing){
            _hint=_hint+"\n\nDISTORTION\nTrack 3. Be_feat.Coco Hsiao\n\nMusic by Printed Noise Lab ©\nAR by Merlin's Mustache Lab ©";
        }
    }
    
    bool checkTouch(ofVec2f pos_){
        if(_play_bound.inside(pos_)){
            setPlay(!_playing);
            return true;
        }
//        else if(_bound.inside(pos_)){
////            int t=ofMap(pos_.x,0,ofGetWidth(),0,_duration);
////            ofNotifyEvent(_event_time,t,this);
////            return true;
//        }
        return false;
    }
    void setPlay(bool play_){
        _play_string=play_?"pause||":"play>>";
        _play_bound=font.getStringBoundingBox(_play_string,_margin,_bound.y);
        //_play_bound.x=ofGetWidth()/2-_play_bound.width/2;
//        ofLog()<<_play_bound;
        
        _playing=play_;
        int p=play_?1:0;
        ofNotifyEvent(_event_play,p,this);
    }
    
};



#endif /* DUIview_h */
