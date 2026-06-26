use glam::{Mat4, Vec3};

use crate::models::render_state::RenderState;
use crate::models::uniforms::Uniforms;

pub fn run(state: &mut RenderState, angle_radians: f32) {
    let aspect = state.config.width as f32 / state.config.height as f32;
    let uniforms = build_uniforms(angle_radians, aspect);
    state
        .queue
        .write_buffer(&state.uniform_buffer, 0, bytemuck::bytes_of(&uniforms));

    let surface_texture = match state.surface.get_current_texture() {
        wgpu::CurrentSurfaceTexture::Success(texture) => texture,
        wgpu::CurrentSurfaceTexture::Suboptimal(texture) => {
            state.surface.configure(&state.device, &state.config);
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
                        r: 0.00,
                        g: 0.00,
                        b: 0.00,
                        a: 0.0,
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

        pass.set_pipeline(&state.pipeline);
        pass.set_bind_group(0, &state.bind_group, &[]);
        pass.set_vertex_buffer(0, state.vertex_buffer.slice(..));
        pass.set_index_buffer(state.index_buffer.slice(..), wgpu::IndexFormat::Uint16);
        pass.draw_indexed(0..state.index_count, 0, 0..1);
    }

    state.queue.submit(Some(encoder.finish()));
    surface_texture.present();
}

fn build_uniforms(angle_radians: f32, aspect: f32) -> Uniforms {
    let model = Mat4::from_rotation_y(angle_radians);
    let view = Mat4::from_translation(Vec3::new(0.0, 0.0, -5.0));
    let projection = Mat4::perspective_rh(45f32.to_radians(), aspect, 0.1, 100.0);
    let mvp = projection * view * model;
    Uniforms {
        mvp: mvp.to_cols_array_2d(),
        model: model.to_cols_array_2d(),
    }
}
