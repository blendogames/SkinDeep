#version 330 core
out vec4 fragColor;

void main() {
    // Keep unlit surfaces readable during greybox development.
    fragColor = vec4(0.10, 0.11, 0.13, 1.0);
}
