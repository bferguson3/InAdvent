uniform vec4 ambience;

in vec3 Normal;
in vec3 FragmentPos;

struct DirLight { 
    vec3 direction;
    vec4 ambient;
    vec4 diffuse;
};

vec4 CalcDirLight(DirLight light, vec3 normal, vec4 baseColor)
{   
    vec3 lightDir = normalize(-light.direction);
    float diff = max(dot(normal, lightDir), 0.0);
    vec4 ambient = light.ambient * baseColor;
    vec4 diffuse = light.diffuse * diff * baseColor;
    return (ambient + diffuse);
}

vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) 
{    
    //diffuse
    vec4 result = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 norm = normalize(Normal); // The normal of the fragment will never change.
    vec4 baseColor = vec4(texture(image, uv)); // We need to know the full value of the pixel
    
    DirLight sun;
    sun.direction = vec3(0.0, -1.0, 0.0);//sunDirection;
    sun.ambient = vec4(0.1, 0.1, 0.1, 1.0);//worldAmbience;
    sun.diffuse = vec4(0.9, 0.9, 0.9, 1.0);//sunColor;
    
    result += CalcDirLight(sun, norm, baseColor);
    //vec4 objectColor = baseColor * vertexColor;

    return result;
}