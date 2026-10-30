#version 330 core

uniform sampler2D uTexture0;
uniform vec4 uProgramEnv[32];

in vec2 vTexCoord;
in vec4 vVertexColor;

out vec4 fragColor;

void main() {
    vec4 texel = texture(uTexture0, vTexCoord);
    vec4 stageColor = uProgramEnv[19];

    // Normal St. Brielle material path:
    // bound stage texture x vertex-color mode x resolved material color.
    fragColor = texel * vVertexColor * stageColor;
}
