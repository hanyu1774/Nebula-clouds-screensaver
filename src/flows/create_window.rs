use winit::event_loop::ActiveEventLoop;
use winit::window::Window;

pub fn run(event_loop: &ActiveEventLoop) -> Window {
    let attrs = Window::default_attributes()
        .with_title("")
        .with_inner_size(winit::dpi::LogicalSize::new(800, 600));
    event_loop.create_window(attrs).unwrap()
}
