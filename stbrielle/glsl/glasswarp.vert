#version 330 core
layout(location = 0) in vec4 aPosition;

uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;

void main() {
    gl_Position = uProjectionMatrix * uModelViewMatrix * aPosition;
}
