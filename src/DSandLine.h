//
//  DSandLine.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/16.
//

#ifndef DSandLine_h
#define DSandLine_h

#define MSAND_REPEAT 2
#define MSAND_SEGMENT 8.0


class DSandLine:public DZigLine{
public:
    
    DSandLine():DSandLine(ofVec3f(0),-1,vector<ofVec3f>(1,ofVec3f(0))){}
    DSandLine(ofVec3f loc_,int last_,vector<ofVec3f> vertex_):DZigLine(loc_,last_,vertex_){
            
        _wid=ofRandom(.2,.3)*rad;
        
        _mesh.clear();
        _mesh.setMode(OF_PRIMITIVE_LINES);
       if(vertex_.size()>1) generateMesh(vertex_);
        
    }
    
    void expandMesh(ofVec3f next_,ofVec3f vert_){
        
//        _mesh.addVertex(_last_vertex);
//        _mesh.addVertex(vert_);
//        _mesh.addTexCoord(ofVec2f(ofRandom(1),_texture_pos));
//        _mesh.addTexCoord(ofVec2f(ofRandom(1),_texture_pos));
        
        float len=vert_.distance(_last_vertex);
        
        float m_=MSAND_REPEAT*MSAND_SEGMENT*2;
        float tp=(float)_mesh.getNumVertices()/m_/(float)_length;
//
        ofVec3f toTheLeft=next_.getRotated(90, ofVec3f(0, 1, 1));
        toTheLeft.normalize();

        for(int j=0;j<MSAND_REPEAT;++j){
            ofVec3f p1_(_last_vertex);
            ofVec3f p2_(vert_);

            ofVec3f d_=toTheLeft*_wid/3.0;//.interpolate(toTheRight,j/3.0);
            p1_+=d_*ofNoise(j*next_.y);
            p2_+=d_*ofNoise(j*next_.x);

            float t=0;
            while(t<1){
                ofVec3f s_=p1_.interpolate(p2_,t);
                s_.x+=ofRandom(-.05,.05)*rad;
                s_.y+=ofRandom(-.05,.05)*rad;

                _mesh.addVertex(s_);
                _mesh.addVertex(s_+next_*len/MSAND_SEGMENT);
                ofColor color_(ofRandom(100,255),ofRandom(50,255),ofRandom(50,150));


                _mesh.addTexCoord(ofVec2f(tp+t/m_,_texture_pos));
                _mesh.addTexCoord(ofVec2f(tp+t/m_,_texture_pos));

//                _mesh.addColor(color_);
//                _mesh.addColor(color_);

                t+=ofRandom(1,2)/MSAND_SEGMENT;
            }
        }

//
        
    }
    void draw(){
        ofPushStyle();
        ofSetColor(255);
        
        
        
        ofSetLineWidth(5);
        ofDisableArbTex();
        
        ofPushMatrix();
        ofTranslate(_loc);
        //        ofRotate(90,vel.x,vel.y,vel.z);
        //        _mesh.drawWireframe();
        _mesh.draw();
        
        ofPopMatrix();
        
        ofPopStyle();
        
    }
  
    
};


#endif /* DSandLine_h */
