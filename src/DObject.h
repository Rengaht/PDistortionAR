//
//  DObject.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/6.
//

#ifndef DObject_h
#define DObject_h

#include "DFlyObject.h"


class DObject{
public:
    static float rad;
    ofVec3f _loc;
    int _last_time;
    bool _forever;
    
    bool _shader_fill;
    int _index_break;
    
    
    DObject(ofVec3f pos):DObject(pos,-1){
        _last_time=0;
    }
    DObject(ofVec3f pos,int last_){
        _loc=pos;
        _last_time=last_;
        _forever=(_last_time==-1);
        ofLog()<<"last_time= "<<last_;
        _shader_fill=false;
        
    }
    virtual void draw(){}
    virtual void update(int dt){
        if(_last_time>0) _last_time-=dt;
    }
    bool dead(){
       // ofLog()<<"dead!";
        return !_forever && _last_time<0;
    }
    
    virtual list<shared_ptr<DFlyObject>> breakdown(){
        list<shared_ptr<DFlyObject>> _fly;
        return _fly;
    }
    virtual void addSegment(ofVec3f add_){}
};

#endif /* DObject_h */
