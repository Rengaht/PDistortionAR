//
//  DRainy.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/6.
//

#ifndef DRainy_h
#define DRainy_h

#include "DObject.h"


class DRainy:public DObject{

    list<ofVec3f> _pt;
    float _vel;
public:
    DRainy(ofVec3f pos,int last_):DObject(pos,last_){
        _vel=rad/ofRandom(2,8);
        generate();
    }
    void generate(){
        int m=floor(ofRandom(10,20));
        for(int i=0;i<m;++i) _pt.push_back(ofVec3f(ofRandom(rad),ofRandom(rad*3),ofRandom(rad)));
    }
    
    void draw(){
        ofPushMatrix();
        ofTranslate(_loc);
        
//        float az=ofRadToDeg(atan2(_loc.x,_loc.y));
//        float el=ofRadToDeg(asin(_loc.z/_loc.length()));
//        ofRotate(az,0,0,1);
//        ofRotate(el,0,1,0);
        
        ofSetColor(255);
        ofNoFill();
        
        for(auto& a:_pt) ofDrawLine(a.x,a.y,a.z,a.x,a.y+_vel*.1,a.z);
        
        ofPopMatrix();
        
    }
    void update(int dt){
        
        DObject::update(dt);
        
        for(auto& a:_pt){
            a.y-=_vel*ofNoise(a.x,a.z);
            if(a.y<0) a.y=ofNoise(a.z*a.x)*rad*3;
        }
    }
    
};

#endif /* DRainy_h */
