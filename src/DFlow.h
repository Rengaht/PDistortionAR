//
//  DFlow.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/9.
//

#ifndef DFlow_h
#define DFlow_h

#define MParticle 4

struct DFlowParticle{
    ofVec3f pos;
    ofVec3f vel;
    ofVec3f acc;
    float rad;
};

class DFlow{
    
    list<DFlowParticle> _particle;
    void generateParticle(int count_){
        for(int i=0;i<count_;++i){
            DFlowParticle p_;
            p_.pos=ofVec3f(ofRandom(_bound.x),_bound.y-_flow_height);
            p_.rad=ofRandom(.5,1);
            _particle.push_back(p_);
        }
    }
    
public:
    static float maxForce;
    static float maxSpeed;
    static float rad;
    
    float _flow_height;
    ofVec2f _bound;
    
    DFlow(){
    }
    DFlow(float hei_){
        _bound.x=ofGetWidth();
        _bound.y=ofGetHeight();
        generateParticle(MParticle);
        _flow_height=hei_;
    }
    
    ofVec2f separate(DFlowParticle& p,list<DFlowParticle>& others){
        
        float desired_separataion=rad*2;
        ofVec2f sum(0);
        int count=0;
        for(auto &b:others){
            float d=p.pos.distance(b.pos);
            if(d>0 && d<desired_separataion){
                ofVec2f diff=p.pos-b.pos;
                diff.normalize();
                
//                if(d<rad){
//                    diff*=maxForce;
//                }else{
                    diff/=d;
//                }
                sum+=diff;
                count++;
            }
        }
//        return sum;
        if(count>0){
            sum/=count;
            sum.normalize();
            sum*=maxSpeed;
            ofVec2f steer=sum-p.vel;
            steer.limit(maxForce);
            return steer;
        }
        return ofVec2f(0);
        
    }
    
    void update(float hei_,ofVec2f f_){
        
        _flow_height=hei_;
        float curr=ofMap(_flow_height,0,1,_bound.x/4,_bound.x/3);
        
        
        f_.normalize();
//        if(f_.y<0) f_.y*=0.5;
//        else f_.y=0;
        f_.y*=-1;
        f_*=maxForce/2;
        for(auto& p:_particle){
            
            
            p.acc=separate(p,_particle);
            p.acc+=f_;
            
//            ofVec2f attract_=p.pos-ofVec2f(_bound.x/2,_bound.y);
//            attract_.normalize();
//            attract_*=maxForce;
//            p.acc+=attract_;
            
            if(p.pos.x<0) p.acc+=ofVec2f(maxForce,0);
            if(p.pos.x>_bound.x) p.acc-=ofVec2f(maxForce,0);
            if(p.pos.y<0) p.acc+=ofVec2f(0,maxForce);
            if(p.pos.y>_bound.y) p.acc-=ofVec2f(0,maxForce);
            
            //p.acc.limit(maxForce);
            
            p.vel+=p.acc;
            p.vel.limit(maxSpeed);
            
            p.pos+=p.vel;
            p.pos.y=ofClamp(p.pos.y,(1-_flow_height)*_bound.y-curr,(1-_flow_height)*_bound.y+curr);
        }
    }
    ofMatrix4x4 getParticleMat(){
        
//        float curr=ofMap(_flow_height,0,1,_bound.x/4,_bound.x/3);
        ofMatrix4x4 mat;
        int i=0;
        for(auto it:_particle){
            
            int ix=floor(i*2/4);
            int iy=floor((i*2)%4);
            int jx=floor((i*2+1)/4);
            int jy=floor((i*2+1)%4);
            
            //cout<<ix<<" , "<<iy<<"  "<<jx<<" , "<<jy<<endl;
            
            mat(ix,iy)=it.pos.x;
            mat(jx,jy)=it.pos.y;
            
            i++;
        }
        //mat(3,2)=curr;
        return mat;
    }
    
    void draw(){
        ofPushStyle();
        ofSetColor(255,0,0);
        for(auto& p:_particle){
            ofDrawCircle(p.pos.x,p.pos.y,5);
        }
        ofPopStyle();
    }
};



#endif /* DFlow_h */
