struct Uniforms
{
    mvp: mat4x4<f32>,
    model: mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

struct VertexInput 
{
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VertexOutput 
{
    @builtin(position) clip_position: vec4<f32>,
    @location(0) world_normal: vec3<f32>,
}

@vertex
fn vs_main(in: VertexInput) -> VertexOutput 
{
    var out: VertexOutput;
    out.clip_position = uniforms.mvp * vec4<f32>(in.position, 1.0);
    let model3 = mat3x3<f32>(uniforms.model[0].xyz, uniforms.model[1].xyz, uniforms.model[2].xyz);
    out.world_normal = model3 * in.normal;
    return out;
}

const SHADOW_COLOR: vec3<f32> = vec3<f32>(0.0, 0.14, 0.0);
const BASE_COLOR: vec3<f32> = vec3<f32>(0.0, 0.25, 0.0);
const HIGHLIGHT_COLOR: vec3<f32> = vec3<f32>(0, 0.937, 0);

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> 
{
    let normal = normalize(in.world_normal);
    let light_direction = normalize(vec3<f32>(0.4, 0.6, 1.0));
    let diffuse = max(dot(normal, light_direction), 0.0);

    var color = mix(SHADOW_COLOR, BASE_COLOR, smoothstep(0.0, 0.55, diffuse));
    color = mix(color, HIGHLIGHT_COLOR, smoothstep(0.55, 1.0, diffuse));
    return vec4<f32>(color, 1.0);
}
