use std::sync::Arc;
use std::time::Instant;
use winit::{
    application::ApplicationHandler,
    event::WindowEvent,
    event_loop::{ActiveEventLoop, EventLoop},
    window::{Window, WindowId},
};

use crate::flows::compile_shader;
use crate::flows::create_uniform_binding;
use crate::flows::create_window;
use crate::flows::handle_input;
use crate::flows::init_gpu;
use crate::flows::mist_binding;
use crate::flows::mist_shader;
use crate::flows::render_frame;
use crate::flows::render_texture;
use crate::flows::resize_surface;
use crate::flows::starfield_shader;
use crate::flows::toggle_fullscreen;
use crate::flows::upload_star_geometry;
use crate::models::input_action::InputAction;
use crate::models::render_state::RenderState;

struct App {
    window: Option<Arc<Window>>,
    state: Option<RenderState>,
    last_frame: Instant,
    start_time: Instant,
    angle: f32,
}

impl Default for App {
    fn default() -> Self {
        let now = Instant::now();
        Self {
            window: None,
            state: None,
            last_frame: now,
            start_time: now,
            angle: 0.0,
        }
    }
}

async fn build_render_state(window: Arc<Window>) -> RenderState {
    let (surface, device, queue, config) = init_gpu::run(window).await;

    let (vertex_buffer, index_buffer, index_count) = upload_star_geometry::run(&device);
    let (uniform_buffer, bind_group_layout, bind_group) = create_uniform_binding::run(&device);
    let pipeline = compile_shader::run(&device, config.format, &bind_group_layout);
    let depth_view = render_texture::run(&device, &config);

    let (mist_uniform_buffer, mist_bind_group_layout, mist_bind_group) = mist_binding::run(&device);
    let mist_pipeline = mist_shader::run(&device, config.format, &mist_bind_group_layout);
    let starfield_pipeline = starfield_shader::run(&device, config.format, &mist_bind_group_layout);

    RenderState {
        surface,
        device,
        queue,
        config,
        pipeline,
        vertex_buffer,
        index_buffer,
        index_count,
        uniform_buffer,
        bind_group,
        depth_view,
        mist_pipeline,
        mist_uniform_buffer,
        mist_bind_group,
        starfield_pipeline,
    }
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.window.is_some() {
            return;
        }
        let window = Arc::new(create_window::run(event_loop));
        let state = pollster::block_on(build_render_state(window.clone()));
        self.window = Some(window);
        self.state = Some(state);
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        let (Some(state), Some(window)) = (self.state.as_mut(), self.window.as_ref()) else {
            return;
        };

        match handle_input::run(&event) {
            InputAction::Quit => event_loop.exit(),
            InputAction::Resize(width, height) => {
                let resized = resize_surface::run(
                    &state.device,
                    &state.surface,
                    &mut state.config,
                    width,
                    height,
                );
                if resized {
                    state.depth_view = render_texture::run(&state.device, &state.config);
                }
            }
            InputAction::ToggleFullscreen => {
                let target = toggle_fullscreen::run(window.fullscreen());
                window.set_fullscreen(target);
            }
            InputAction::Redraw => {
                let now = Instant::now();
                let dt = (now - self.last_frame).as_secs_f32();
                self.last_frame = now;
                self.angle += dt * 0.8;
                let elapsed = (now - self.start_time).as_secs_f32();

                render_frame::run(state, self.angle, elapsed);
                window.request_redraw();
            }
            InputAction::Ignore => {}
        }
    }
}

pub fn run() {
    let event_loop = EventLoop::new().unwrap();
    let mut app = App::default();
    event_loop.run_app(&mut app).unwrap();
}
