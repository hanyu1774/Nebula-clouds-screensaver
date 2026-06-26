struct MistUniforms {
    time: f32,
    aspect: f32,
    pad0: f32,
    pad1: f32,
};
@group(0) @binding(0) var<uniform> mist: MistUniforms;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

// One oversized triangle covering the whole screen and no vertex buffer needed.
@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    let positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    let pos = positions[vertex_index];

    var out: VertexOutput;
    out.clip_position = vec4<f32>(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + vec2<f32>(0.5, 0.5);
    return out;
}

fn hash(p: vec2<f32>) -> f32 {
    var p3 = fract(vec3<f32>(p.x, p.y, p.x) * vec3<f32>(0.1031, 0.1030, 0.0973));
    p3 = p3 + dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let a = hash(i);
    let b = hash(i + vec2<f32>(1.0, 0.0));
    let c = hash(i + vec2<f32>(0.0, 1.0));
    let d = hash(i + vec2<f32>(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 4 octaves of noise stacked together; this is what gives the
// mist its wispy, layered look instead of one smooth blob.
fn fbm(p: vec2<f32>) -> f32 {
    var value: f32 = 0.0;
    var amplitude: f32 = 0.5;
    var freq: vec2<f32> = p;
    for (var i: i32 = 0; i < 4; i = i + 1) {
        value = value + amplitude * noise(freq);
        freq = freq * 2.0;
        amplitude = amplitude * 0.5;
    }
    return value;
}

// constraint, as a single named value: green never exceeds 144/255.
const MAX_GREEN: f32 = 64.0 / 255.0;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var uv = in.uv;
    uv.x = uv.x * mist.aspect; // keep the noise pattern square regardless of window shape

    // speed of the moving clouds
    let drift = vec2<f32>(mist.time * 0.13, mist.time * 0.015); // movement speed
    let scale = 2.2; // cloud size -- bigger = larger, fewer clouds

    let n1 = fbm(uv * scale + drift);
    let n2 = fbm(uv * scale * 1.7 - drift * 1.3 + vec2<f32>(5.2, 1.3));
    let density = clamp(n1 * 0.6 + n2 * 0.4, 0.0, 1.0);

    let green = density * MAX_GREEN;                          // pure green gradient
    let alpha = clamp(density - 0.35, 0.0, 1.0) * 0.6;          // 0.35 = coverage threshold

    return vec4<f32>(0.0, green, 0.0, alpha);
}
