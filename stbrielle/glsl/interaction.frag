#version 330 core
in vec3 vNormal;
out vec4 fragColor;

void main() {
    // Keep the additive interaction pass subtle in greybox mode. Real
    // St. Brielle lighting will replace this later.
    vec3 n = abs(normalize(vNormal));
    float facing = 0.012 + n.z * 0.010 + n.x * 0.006 + n.y * 0.004;
    fragColor = vec4(vec3(facing), 1.0);
}
