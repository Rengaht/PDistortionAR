//
//  DRecord.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/5.
//

#ifndef DRecord_h
#define DRecord_h


#include "DObject.h"

class DRecord:public DObject{
    
public:
    ofMesh _mesh;
    vector<ofVec3f> _vertex;
    float _texture_pos;
    float _texture_vel;
    ofMatrix4x4 _mat_projection,_mat_view;
    
public:
    DRecord():DObject(ofVec3f(0),-1){}
    DRecord(ofVec3f loc_):DObject(loc_,-1){
        
         _texture_pos=ofRandom(1);
        _texture_vel=ofRandom(100,200);
    }
    void addVertex(ofVec3f world_pos_,ofVec2f screen_pos_){
        
        float m=_mesh.getNumVertices();
        if(m==0){
            _mesh.setMode(OF_PRIMITIVE_LINES);
            _texture_pos=screen_pos_.y;
        }
        
//        _vertex.push_back(world_pos_);
        _mesh.addVertex(world_pos_);
        _mesh.addTexCoord(ofVec2f(1.0,_texture_pos));
        
        for(int i=0;i<m;++i){
            _mesh.setTexCoord(i,ofVec2f(i/m,_texture_pos));
        }
        
    }
    
    void draw(){
        ofPushStyle();
        ofSetLineWidth(10);
        ofDisableArbTex();

        ofPushMatrix();
        //ofTranslate(loc);
        //ofRotate(90,vel.x,vel.y,vel.z);
        _mesh.draw();
        
        
        ofPopMatrix();
        
        ofPopStyle();
        
        
    }
    void update(ofMatrix4x4 projection,ofMatrix4x4 view){
        _mat_projection=projection;
        _mat_view=view;
        
        _mesh.clear();
        for(auto& p:_vertex){
            ofVec2f s=ARCommon::worldToScreen(p,_mat_projection,_mat_view);
            _mesh.addVertex(p);
            _mesh.addTexCoord(s);
        }
    }
    
    list<DFlyObject*> breakdown(){
        list<DFlyObject*> _fly;
        
        int m=_mesh.getNumVertices();
        for(int i=0;i<m-1;++i){
//            vector<ofVec3f> line_;
//            line_.push_back(_mesh.getVertex(i+1)-_mesh.getVertex(i));
            ofMesh mesh_;
            mesh_.setMode(OF_PRIMITIVE_LINES);
            
            for(int j=0;j<2;++j){
                mesh_.addVertex(_mesh.getVertex(i+j)-_mesh.getVertex(i));
                mesh_.addTexCoord(_mesh.getTexCoord(i+j));
            }
            
            _fly.push_back(new DFlyObject(_mesh.getVertex(i),mesh_));
        }
        
        return _fly;
    }
};


#endif /* DRecord_h */
