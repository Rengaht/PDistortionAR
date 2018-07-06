precision highp float;

uniform sampler2D inputImageTexture;
varying vec2 texCoord;



void main(){
    vec4 col = texture2D(inputImageTexture, texCoord);
    
    gl_FragColor = vec4(col);
}
