#version 330 core

layout(location = 0) in vec4 aPosition;
layout(location = 1) in vec2 aTexCoord;
layout(location = 5) in vec4 aColor;

uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;
uniform mat4 uTextureMatrix;
uniform vec4 uProgramEnv[32];

out vec2 vTexCoord;
out vec4 vVertexColor;

void main() {
    gl_Position = uProjectionMatrix * uModelViewMatrix * aPosition;

    vec4 tc = uTextureMatrix * vec4(aTexCoord, 0.0, 1.0);
    vTexCoord = tc.xy;

    // Mirrors the fixed-function vertexColor behavior:
    // IGNORE => white, MODULATE => vertex color,
    // INVERSE_MODULATE => 1 - vertex color.
    vVertexColor = aColor * uProgramEnv[16] + uProgramEnv[17];
}
