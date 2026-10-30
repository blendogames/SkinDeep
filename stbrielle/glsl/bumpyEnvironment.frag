#version 330 core
uniform vec4 uProgramEnv[32];
out vec4 fragColor;

void main() {
    vec4 c = uProgramEnv[19];
    if (c.a <= 0.001) {
        c = vec4(0.18, 0.19, 0.22, 1.0);
    }
    fragColor = c;
}
