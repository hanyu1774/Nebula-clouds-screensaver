struct Uniforms
{
    mvp: mat4x4<f32>,
    model: mat4x4<f32>,
    time: f32,
    pad0: f32,
    pad1: f32,
    pad2: f32,
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

// The base duration of one stage, in seconds. Most stages last exactly
// this long. A few stages last longer, see STAGE_DURATION_MULTIPLIERS
// below for the per-stage multiplier that decides by how much.
const SECONDS_PER_STAGE: f32 = 16.0;

// How many SECONDS_PER_STAGE units each stage lasts. Index N here
// lines up with stage N in evaluate_stage further down. A value of
// 1.0 means a normal length stage, 2.0 means twice as long, and so
// on. Pure black and frosty glass are set to linger twice as long as
// the rest, since they are the calmest part of the cycle and read
// better with extra time on screen. Change either number here to
// retune how long that one stage lasts, nothing else needs to change.
const STAGE_DURATION_MULTIPLIERS: array<f32, 7> = array<f32, 7>(
    4.0, // stage 0, pure white
    4.0, // stage 1, the original green
    1.0, // stage 2, light blue
    1.0, // stage 3, ultramarine blue
    1.0, // stage 4, lavender blue
    24.0, // stage 5, pure black,
    14.0, // stage 6, frosty glass,
);

const STAGE_COUNT: i32 = 7;

// ---------------------------------------------------------------------
// Color cycle overview
//
// The star fades through the stages below, in this order, then loops
// back to stage 0 once stage 6 finishes. The numbers match the
// "stage == N" checks used in evaluate_stage further down, so any
// color can be found quickly by searching for its stage number.
//
// 0  pure white               flat, no shading
// 1  the star's original green color, moved here from stage 0
// 2  light blue                hex 73a9e6, already in this file
// 3  ultramarine blue          already in this file
// 4  lavender blue              hex 6d84ff, already in this file
// 5  pure black                flat, no shading, lingers twice as long
// 6  frosty glass              transparent rim highlight, already in this file, lingers twice as long
// ---------------------------------------------------------------------

// Stage 1, the star's original green color. The values are left
// untouched, this color simply no longer plays right at the start of
// the cycle, it now plays right after the new white opening color
// instead, see stage 0 below for that starting color.
const SHADOW_COLOR: vec3<f32> = vec3<f32>(0.0, 0.047058823529411764, 0.0);
const BASE_COLOR: vec3<f32> = vec3<f32>(0.0, 0.25, 0.0);
const HIGHLIGHT_COLOR: vec3<f32> = vec3<f32>(0.0, 0.937, 0.0);

// Stage 2, light blue, hex 73a9e6. Already in this file, value left
// unchanged, only the stage number and the constant name changed since
// this color now plays much later in the cycle than before.
const LIGHT_BLUE_BASE: vec3<f32> = vec3<f32>(0.4510, 0.6627, 0.9020);
// Stage 3, ultramarine blue. Already in this file, value left
// unchanged.
const ULTRAMARINE_BLUE_BASE: vec3<f32> = vec3<f32>(0.125, 0.298, 0.953);
// Stage 4, lavender blue, hex 6d84ff. Already in this file, value
// left unchanged.
const LAVENDER_BLUE_BASE: vec3<f32> = vec3<f32>(0.4275, 0.5176, 1.0);

// Stage 6, frosty glass. A very light, slightly blue tint, kept apart
// from the other base colors above because this stage also needs its
// own alpha value, which none of the others do. Already in this file,
// value left unchanged.
const FROSTY_GLASS_TINT: vec3<f32> = vec3<f32>(0.85, 0.93, 0.98);

// Stage 0, pure white, the starting color of the cycle. Flat and
// unlit, no shadow or highlight, the same treatment as pure black
// below. Already in this file, value left unchanged.
const WHITE_FLAT: vec3<f32> = vec3<f32>(1.0, 1.0, 1.0);
// Stage 5, pure black. Flat and unlit, no shadow or highlight.
// Already in this file, value left unchanged.
const BLACK_FLAT: vec3<f32> = vec3<f32>(0.0, 0.0, 0.0);

// Derives a shadow tone from any base color by darkening it toward
// black while keeping the same hue. 0.22 mirrors how dark the original
// green shadow sits relative to its own base color.
fn shadow_of(base: vec3<f32>) -> vec3<f32> {
    return base * 0.22;
}

// Derives a highlight tone from any base color by lightening it toward
// white and then boosting it a little further, mirroring how much
// brighter the original green highlight sits relative to its own base.
fn highlight_of(base: vec3<f32>) -> vec3<f32> {
    let lightened = mix(base, vec3<f32>(1.0, 1.0, 1.0), 0.45);
    return clamp(lightened * 1.15, vec3<f32>(0.0, 0.0, 0.0), vec3<f32>(1.0, 1.0, 1.0));
}

// Shades a base color using the same shadow, base, highlight ramp the
// original green star uses, just with a derived shadow and highlight
// instead of hand picked ones.
fn shade(base: vec3<f32>, diffuse: f32) -> vec3<f32> {
    var color = mix(shadow_of(base), base, smoothstep(0.0, 0.55, diffuse));
    color = mix(color, highlight_of(base), smoothstep(0.55, 1.0, diffuse));
    return color;
}

// Returns the fully shaded color, alpha included, for one discrete
// stage of the cycle described in the overview comment above. diffuse
// drives the normal shadow and highlight ramp used by every stage
// except the flat white and black stages and the original green
// stage. fresnel drives the rim based look used by the frosty glass
// stage, since that one depends on how much a facet faces the camera
// rather than how much it faces the light.
fn evaluate_stage(stage: i32, diffuse: f32, fresnel: f32) -> vec4<f32> {
    if (stage == 0) {
        // Pure white, flat and unlit, no shadow or highlight.
        return vec4<f32>(WHITE_FLAT, 1.0);
    }
    if (stage == 1) {
        // The star's original green look, kept exactly as it was
        // before, just moved here instead of being the starting color.
        var color = mix(SHADOW_COLOR, BASE_COLOR, smoothstep(0.0, 0.55, diffuse));
        color = mix(color, HIGHLIGHT_COLOR, smoothstep(0.55, 1.0, diffuse));
        return vec4<f32>(color, 1.0);
    }
    if (stage == 2) {
        return vec4<f32>(shade(LIGHT_BLUE_BASE, diffuse), 1.0);
    }
    if (stage == 3) {
        return vec4<f32>(shade(ULTRAMARINE_BLUE_BASE, diffuse), 1.0);
    }
    if (stage == 4) {
        return vec4<f32>(shade(LAVENDER_BLUE_BASE, diffuse), 1.0);
    }
    if (stage == 5) {
        // Pure black, flat and unlit, no shadow or highlight.
        return vec4<f32>(BLACK_FLAT, 1.0);
    }
    // Stage 6, frosty glass. No directional shadow or highlight, the
    // rim term takes their place instead. The middle of each facet
    // stays mostly see through, the rim catches the light and turns
    // almost white, the way light catches the edge of a piece of
    // frosted glass.
    let rim = smoothstep(0.35, 0.95, fresnel);
    let color = mix(FROSTY_GLASS_TINT, vec3<f32>(1.0, 1.0, 1.0), rim);
    let alpha = clamp(0.18 + rim * 0.67, 0.0, 0.85);
    return vec4<f32>(color, alpha);
}

// How far the star is through the color cycle right now. Unlike a
// plain "every stage is the same length" timeline, this walks through
// STAGE_DURATION_MULTIPLIERS so stages can be longer or shorter than
// one another. current_stage and next_stage are which two colors to
// blend between, local_t is how far along that blend is, 0 right
// after current_stage starts and 1 right before next_stage takes
// over.
struct StageProgress {
    current_stage: i32,
    next_stage: i32,
    local_t: f32,
}

// Adds up every stage's length to get the total time one full loop
// of the cycle takes, in seconds.
fn total_cycle_seconds() -> f32 {
    var total = 0.0;
    for (var i = 0; i < STAGE_COUNT; i = i + 1) {
        total = total + STAGE_DURATION_MULTIPLIERS[i] * SECONDS_PER_STAGE;
    }
    return total;
}

fn stage_progress(time_seconds: f32) -> StageProgress {
    let time_in_cycle = time_seconds % total_cycle_seconds();

    var elapsed = 0.0;
    for (var i = 0; i < STAGE_COUNT; i = i + 1) {
        let stage_length = STAGE_DURATION_MULTIPLIERS[i] * SECONDS_PER_STAGE;
        if (time_in_cycle < elapsed + stage_length) {
            var progress: StageProgress;
            progress.current_stage = i;
            progress.next_stage = (i + 1) % STAGE_COUNT;
            progress.local_t = smoothstep(0.0, 1.0, (time_in_cycle - elapsed) / stage_length);
            return progress;
        }
        elapsed = elapsed + stage_length;
    }

    // Not reachable, time_in_cycle is always less than the total by
    // construction. Kept only so every path returns a value.
    var fallback: StageProgress;
    fallback.current_stage = 0;
    fallback.next_stage = 1;
    fallback.local_t = 0.0;
    return fallback;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> 
{
    let normal = normalize(in.world_normal);
    let light_direction = normalize(vec3<f32>(0.4, 0.6, 1.0));
    let diffuse = max(dot(normal, light_direction), 0.0);

    // The camera never moves and sits roughly along the positive Z
    // axis relative to the star, see the fixed view transform in
    // render_frame.rs. The star is small compared to the camera
    // distance, so a constant view direction is a close enough stand
    // in for a real camera position uniform, without adding one just
    // for this.
    let view_direction = vec3<f32>(0.0, 0.0, 1.0);
    let fresnel = pow(1.0 - max(dot(normal, view_direction), 0.0), 2.5);

    let progress = stage_progress(uniforms.time);
    let current_color = evaluate_stage(progress.current_stage, diffuse, fresnel);
    let next_color = evaluate_stage(progress.next_stage, diffuse, fresnel);

    return mix(current_color, next_color, progress.local_t);
}
