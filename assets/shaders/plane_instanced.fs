#version 330

// Input vertex attributes (from vertex shader)
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

void main()
{
    // Texel color fetching from texture sampler
    vec4 texelColor = texture(texture0, fragTexCoord);

    vec3 up = vec3(1.0, 0.0, 0.0);
    float range = 0.7; // shift the range of shadow to not include the 30% darkest shades
    float shade = (dot(up, fragNormal) * range * 0.5) + 0.5 + ((1 - range) / 2);
    vec4 shadedColor = vec4(colDiffuse.rgb * shade, colDiffuse.a);

    finalColor = texelColor*shadedColor;
}
