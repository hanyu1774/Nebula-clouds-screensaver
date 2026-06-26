struct SkyUniforms {
    time: f32,
    aspect: f32,
    pad0: f32,
    pad1: f32,
};
@group(0) @binding(0) var<uniform> sky: SkyUniforms;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

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

fn hash21(p: vec2<f32>) -> f32 {
    var p3 = fract(vec3<f32>(p.x, p.y, p.x) * vec3<f32>(0.1031, 0.1030, 0.0973));
    p3 = p3 + dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

fn star_layer(uv: vec2<f32>, cell_size: f32, time: f32, density: f32, glint_chance: f32, min_radius: f32, max_radius: f32) -> vec3<f32> {
    let grid_uv = uv / cell_size;
    let base_cell = floor(grid_uv);

    var total = vec3<f32>(0.0);

    // Check this pixel's cell and its 8 neighbors, so a star sitting near
    // a cell edge still gets to draw its full spike into the next cell
    // over, instead of being clipped at the boundary.
    for (var dy: i32 = -1; dy <= 1; dy = dy + 1) {
        for (var dx: i32 = -1; dx <= 1; dx = dx + 1) {
            let cell = base_cell + vec2<f32>(f32(dx), f32(dy));

            let presence = hash21(cell);
            if (presence > density) {
                continue;
            }

            let star_pos = vec2<f32>(hash21(cell + 4.7), hash21(cell + 9.3));
            let star_center = cell + star_pos;
            let offset = grid_uv - star_center;
            let world_offset = offset * cell_size;
            let dist = length(world_offset);

            let brightness_seed = hash21(cell + 13.1);
            let size_seed = hash21(cell + 22.6);
            let phase = hash21(cell + 31.4) * 6.2831;
            let twinkle = 0.65 + 0.35 * sin(time * (0.6 + brightness_seed * 1.2) + phase);

            let radius = mix(min_radius, max_radius, size_seed);
            var glow = smoothstep(radius, 0.0, dist);

            let is_glint = hash21(cell + 41.9) < glint_chance;
            if (is_glint) {
                let arm_width = radius * 0.3;
                let arm_length = radius * 9.0;
                let horizontal = smoothstep(arm_width, 0.0, abs(world_offset.y)) * smoothstep(arm_length, 0.0, abs(world_offset.x));
                let vertical = smoothstep(arm_width, 0.0, abs(world_offset.x)) * smoothstep(arm_length, 0.0, abs(world_offset.y));
                glow = max(glow, max(horizontal, vertical) * 0.85);
            }

            let brightness = mix(0.25, 1.0, brightness_seed) * twinkle;

            let tint_seed = hash21(cell + 51.2);
            var tint = vec3<f32>(1.0, 1.0, 1.0);
            if (tint_seed < 0.18) {
                tint = vec3<f32>(1.0, 0.78, 0.55);
            } else if (tint_seed > 0.85) {
                tint = vec3<f32>(0.75, 0.85, 1.0);
            }

            total = max(total, tint * glow * brightness);
        }
    }

    return total;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var uv = in.uv;
    uv.x = uv.x * sky.aspect;

    var color = vec3<f32>(0.0);
    color += star_layer(uv, 0.045, sky.time, 0.55, 0.00, 0.0015, 0.0035);
    color += star_layer(uv, 0.085, sky.time, 0.32, 0.05, 0.0035, 0.006);
    color += star_layer(uv, 0.16,  sky.time, 0.20, 0.20, 0.005,  0.009);

    color = clamp(color, vec3<f32>(0.0), vec3<f32>(1.0));
    let alpha = clamp(max(color.r, max(color.g, color.b)), 0.0, 1.0);
    return vec4<f32>(color, alpha);
}
