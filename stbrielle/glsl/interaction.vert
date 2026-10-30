#version 330 core
layout(location = 0) in vec4 aPosition;
layout(location = 2) in vec3 aNormal;

uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;

out vec3 vNormal;

void main() {
    gl_Position = uProjectionMatrix * uModelViewMatrix * aPosition;
    vNormal = normalize(aNormal);
}
