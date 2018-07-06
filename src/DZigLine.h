//
//  DZigLine.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/5.
//

#ifndef DZigLine_h
#define DZigLine_h

#include "DObject.h"


class DZigLine:public DObject{
    
    ofMesh _mesh;
    int _vel;
    int _length;
    float _texture_pos;
    
    void addVertex(){
        
        float r=DObject::rad*ofRandom(.8,1.2);
        int i=_mesh.getNumVertices();
        
        _mesh.addVertex(ofVec3f(r*i+r*ofRandom(-.4,.4),rad+r*ofRandom(-.4,.4),rad+r*ofRandom(-.4,.4)));
        _mesh.addTexCoord(ofVec2f((float)i/_length,_texture_pos));
    }
public:
    DZigLine(ofVec3f loc_):DZigLine(loc_,-1){}
    DZigLine(ofVec3f loc_,int last_):DObject(loc_,last_){
        
        _length=floor(ofRandom(20,50));
        _vel=floor(ofRandom(10,40));
        
        _texture_pos=ofRandom(1);
        _mesh.setMode(OF_PRIMITIVE_LINE_STRIP);
        
        generateMesh();
        
    }
    void generateMesh(){
        
        int m=ofRandom(3,_length/3);
        for(int i=0;i<m;++i){
            addVertex();
        }
        
    }
    
    void draw(){
        ofPushStyle();
        ofSetLineWidth(5);
        ofDisableArbTex();
        
        ofPushMatrix();
        ofTranslate(_loc);
//        ofRotate(90,vel.x,vel.y,vel.z);
        _mesh.draw();
        ofPopMatrix();
        
        ofPopStyle();
        
    }
    
    void update(int dt_){
        
        DObject::update(dt_);
        
        if(_mesh.getNumVertices()<_length) addVertex();
        else _mesh.clear();
    }
    
    
    
};
#endif /* DZigLine_h */
