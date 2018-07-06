attribute vec4 position;
attribute vec4 color;
attribute vec4 normal;
attribute vec2 texcoord;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

varying vec2 texCoord;

void main() {
    gl_Position	= projectionMatrix * modelViewMatrix * position;
    //gl_FragCoord[0] = gl_MultiTexCoord0;
    texCoord=texcoord;
}
