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
    
    
    void addVertex(){
        
        float r=DObject::rad*ofRandom(.8,1.2);
        int i=_mesh.getNumVertices();
        
        _mesh.addVertex(ofVec3f(r*i+r*ofRandom(-.4,.4),rad+r*ofRandom(-.4,.4),rad+r*ofRandom(-.4,.4)));
        _mesh.addTexCoord(ofVec2f((float)i/_vertex_length,_texture_pos));
    }
   
public:
    ofMesh _mesh;
    float _texture_pos;
    ofVec3f _last_vertex;
    ofVec3f _last_dir;
    float _wid;
    int _vertex_length;
    
    float _dest_length;
    
    vector<ofVec3f> _record_vertex;
    
    DZigLine():DZigLine(ofVec3f(0)){}
    DZigLine(ofVec3f loc_):DZigLine(loc_,-1,vector<ofVec3f>(1,loc_)){}
    DZigLine(ofVec3f loc_,int last_,vector<ofVec3f> vertex_):DObject(loc_,last_){
        
        
        _texture_pos=ofRandom(1);
//        _mesh.setMode(OF_PRIMITIVE_LINE_STRIP);
        _mesh.setMode(OF_PRIMITIVE_TRIANGLE_STRIP);
        
        
        _last_vertex=ofVec3f(0);
        _last_dir=ofVec3f(1,0,0);
        _last_dir.rotate(ofRandom(360),ofVec3f(0,1,0));
        
        _wid=ofRandom(.2,.6)*rad;
//        _shader_fill=true;
        
        //if(vertex_.size()>1) generateMesh(vertex_);
        
        _dest_length=floor(ofRandom(30,150));
        
    }
    void generateMesh(vector<ofVec3f> vertex_){
        
        _vertex_length=vertex_.size();
//        _loc=vertex_[0];
//
//        _last_vertex=ofVec3f(0);
        
        for(int i=0;i<_vertex_length;++i){
            addSegment(vertex_[i]);
            
        }
        
    }

    void addSegment(ofVec3f vert_){
        
        int m=_mesh.getNumVertices();
        if(m>_dest_length){
            ofLog()<<"exceed vertex size! "<<m<<" "<<_dest_length;
            return;
            
        }
        
        //float r=DObject::rad*ofRandom(.1,.8);
        
        if(_mesh.getNumVertices()<1){
            _loc=vert_;
            _last_vertex=ofVec3f(0);
//            return;
        }
        
        vert_-=_loc;
        
        ofVec3f next_=vert_-_last_vertex;
        next_.normalize();
        
        expandMesh(next_,vert_);
        
        _last_dir=next_;
        _last_vertex=vert_;
        
    }
    
    virtual void expandMesh(ofVec3f next_,ofVec3f vert_){
        
        int m=_mesh.getNumVertices();
        ofVec3f toTheLeft=next_.getRotated(90, ofVec3f(0, 1, 1));
        ofVec3f toTheRight=next_.getRotated(-90, ofVec3f(0, 1, 1));
        
        float twid_=_wid*(1-m/_dest_length);
        _mesh.addVertex(_last_vertex+toTheLeft*twid_);
        _mesh.addVertex(_last_vertex+toTheRight*twid_);
        
//                ofColor color_(ofRandom(100,255),ofRandom(50,255),ofRandom(50,150));
//                _mesh.addColor(color_);
//                _mesh.addColor(color_);
        
        _mesh.addTexCoord(ofVec2f(1,_texture_pos));
        _mesh.addTexCoord(ofVec2f(1,_texture_pos));
        for(float i=0;i<m;i+=2){
            _mesh.setTexCoord(i,ofVec2f(i/2/m,_texture_pos));
            _mesh.setTexCoord(i+1,ofVec2f(i/2/m,_texture_pos+_wid));
        }
        
        
    }
    
    virtual void draw(){
        ofPushStyle();
        ofSetColor(255);
        
        
        
//        ofSetLineWidth(2);
        ofDisableArbTex();
        
        ofPushMatrix();
        ofTranslate(_loc);
//        ofRotate(90,vel.x,vel.y,vel.z);
//        _mesh.drawWireframe();
        _mesh.draw();
        
        ofPopMatrix();
        
        ofPopStyle();
        
    }
    
    virtual void update(int dt_){
        
        DObject::update(dt_);
        
    }
    
    vector<DFlyObject*> breakdown(){
        vector<DFlyObject*> _fly;
        
        int m=_mesh.getNumVertices();
        
        for(int i=0;i<m-1;){
//            vector<ofVec3f> line_;
//            line_.push_back(_mesh.getVertex(i+1));
            ofMesh mesh_;
            mesh_.setMode(OF_PRIMITIVE_TRIANGLE_STRIP);
            int k=ofRandom(1,3)*2;
            
            ofVec3f loc=_mesh.getVertex(i);
            
            
            for(int j=0;j<k;++j){
                mesh_.addVertex(_mesh.getVertex(i+j)-loc);
                mesh_.addTexCoord(_mesh.getTexCoord(i+j)-loc);
            }
            _fly.push_back(new DFlyObject(_loc,mesh_));
            
            i+=k;
        }
        
        return _fly;
    }
    
    
};
#endif /* DZigLine_h */
