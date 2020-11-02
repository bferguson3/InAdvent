out vec3 FragmentPos;
out vec3 Normal;
out vec3 CameraPos;

vec4 position(mat4 projection, mat4 transform, vec4 vertex) { 
    Normal = (lovrNormalMatrix * lovrNormal).xyz; 
    FragmentPos = (lovrModel * vertex).xyz;
    CameraPos = -lovrView[3].xyz * mat3(lovrView);
    return projection * transform * vertex;
}