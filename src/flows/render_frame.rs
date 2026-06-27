use glam::{Mat4, Vec3};

use crate::flows::render_texture;
use crate::models::mist_uniforms::MistUniforms;
use crate::models::render_state::RenderState;
use crate::models::uniforms::Uniforms;

pub fn run(state: &mut RenderState, angle_radians: f32, time_seconds: f32) {
    let aspect = state.config.width as f32 / state.config.height as f32;

    let star_uniforms = build_star_uniforms(angle_radians, aspect, time_seconds);
    state
        .queue
        .write_buffer(&state.uniform_buffer, 0, bytemuck::bytes_of(&star_uniforms));

    let mist_uniforms = build_mist_uniforms(time_seconds, aspect);
    state.queue.write_buffer(
        &state.green_mist_uniform_buffer,
        0,
        bytemuck::bytes_of(&mist_uniforms),
    );

    let surface_texture = match state.surface.get_current_texture() {
        wgpu::CurrentSurfaceTexture::Success(texture) => texture,
        wgpu::CurrentSurfaceTexture::Suboptimal(texture) => {
            // Do not call surface.configure() here. `texture` above has
            // already been acquired from the surface and not yet
            // presented, and wgpu refuses to reconfigure a surface
            // while an acquired SurfaceTexture for it is still alive.
            // wgpu-core calls this case `PreviousOutputExists`, and it
            // is exactly the panic this comment is fixing:
            // "`SurfaceOutput` must be dropped before a new `Surface`
            // is made". A suboptimal texture is still valid to draw to
            // and present, it only means the surface would benefit
            // from a reconfigure. The resize handler in workflow.rs
            // already reconfigures the surface whenever winit reports
            // a real size change, including the one that fires right
            // after toggling fullscreen, so the correct thing to do
            // here is just treat this the same as a normal frame and
            // let that handler do the reconfiguring.
            texture
        }
        wgpu::CurrentSurfaceTexture::Outdated => {
            state.surface.configure(&state.device, &state.config);
            return;
        }
        wgpu::CurrentSurfaceTexture::Timeout
        | wgpu::CurrentSurfaceTexture::Occluded
        | wgpu::CurrentSurfaceTexture::Validation => return,
        wgpu::CurrentSurfaceTexture::Lost => return,
    };
    let tex_size = surface_texture.texture.size();
    if tex_size.width != state.config.width || tex_size.height != state.config.height {
        state.config.width = tex_size.width;
        state.config.height = tex_size.height;

        // VIOLATION!! DON'T USE A FLOW INSIDE ANOTHER FLOW!
        // Need to fix that later.
        // For now, this fixes the fullscreen crash
        state.depth_view = render_texture::run(&state.device, &state.config);
    }
    let view = surface_texture
        .texture
        .create_view(&wgpu::TextureViewDescriptor::default());
    let mut encoder = state
        .device
        .create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

    {
        let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("star_pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view: &view,
                resolve_target: None,
                depth_slice: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color {
                        r: 0.0,
                        g: 0.0,
                        b: 0.0,
                        a: 1.0,
                    }),
                    store: wgpu::StoreOp::Store,
                },
            })],
            depth_stencil_attachment: Some(wgpu::RenderPassDepthStencilAttachment {
                view: &state.depth_view,
                depth_ops: Some(wgpu::Operations {
                    load: wgpu::LoadOp::Clear(1.0),
                    store: wgpu::StoreOp::Store,
                }),
                stencil_ops: None,
            }),
            timestamp_writes: None,
            occlusion_query_set: None,
            multiview_mask: None,
        });
        pass.set_pipeline(&state.starfield_pipeline);
        pass.set_bind_group(0, &state.green_mist_bind_group, &[]);
        pass.draw(0..3, 0..1);

        pass.set_pipeline(&state.nebula_pipeline);
        pass.set_bind_group(0, &state.green_mist_bind_group, &[]); // same buffer, time and aspect only
        pass.draw(0..3, 0..1);

        pass.set_pipeline(&state.green_mist_pipeline);
        pass.set_bind_group(0, &state.green_mist_bind_group, &[]);
        pass.draw(0..3, 0..1);

        pass.set_pipeline(&state.pipeline);
        pass.set_bind_group(0, &state.bind_group, &[]);
        pass.set_vertex_buffer(0, state.vertex_buffer.slice(..));
        pass.set_index_buffer(state.index_buffer.slice(..), wgpu::IndexFormat::Uint16);
        pass.draw_indexed(0..state.index_count, 0, 0..1);
    }

    state.queue.submit(Some(encoder.finish()));
    surface_texture.present();
}

fn build_star_uniforms(angle_radians: f32, aspect: f32, time_seconds: f32) -> Uniforms {
    let model = Mat4::from_rotation_y(angle_radians);
    let view = Mat4::from_translation(Vec3::new(0.0, 0.0, -5.0));
    let projection = Mat4::perspective_rh(45f32.to_radians(), aspect, 0.1, 100.0);
    let mvp = projection * view * model;
    Uniforms {
        mvp: mvp.to_cols_array_2d(),
        model: model.to_cols_array_2d(),
        time: time_seconds,
        _pad0: 0.0,
        _pad1: 0.0,
        _pad2: 0.0,
    }
}

fn build_mist_uniforms(time_seconds: f32, aspect: f32) -> MistUniforms {
    MistUniforms {
        time: time_seconds,
        aspect,
        _pad0: 0.0,
        _pad1: 0.0,
    }
}
