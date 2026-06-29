# Nebula clouds screensaver

I made this screensaver using Rust and WGSL. There are two versions (see Downloads / Releases). One without a star, the other with a star. See following pictures:

<img width="1874" height="1007" alt="nebula_clouds" src="https://github.com/user-attachments/assets/b7e51f5f-92e7-44bd-9de8-aeb44d065839" />
<img width="1874" height="1007" alt="nebula_clouds_with_3d_star" src="https://github.com/user-attachments/assets/f1f33404-c32c-4d49-83ff-4afd2771e886" />

In both versions (with or without the 3D star), you will see nebula clouds that move in space. Their colors will change and some of the clouds will disappear. 
In the background you will see stars, some of them are glim stars.

In the version, where you can see a 3D star:
* It will spin in a circle
* Its colors will change over time.

In this entire project, no object file is used. Everything is rendered via WGSL. The vertices and indices of the 3D star are found in `src/models/star_geometry.rs`.

## Code structure briefly explained

You will see four folders in `src/`. The code follows the IOSP and Separation of Concerns principles. Each responsibility is found in the following folders:

* `models/`: Pure data
* `flows/`: tasks
* `workflows/`: orchestration of tasks
* `wgsl/`: the WGSL instructions can be found here.

The main function `run()` in the file `src/workflows/workflow.rs` is used in `src/main.rs` to run the whole application.

## Used dependencies

* `bytemuck`
* `glam`
* `pollster`
* `wgpu`
* `winit`

## Compilation
* You need the Rust SDK. If you don't have it, you need to install it. Make sure to install `rustup` and `cargo` (in Windows, `cargo` is probably included in the Rust SDK).
* Download this repo or clone it.
* Open the console / terminal, navigate to the location where the downloaded repo is.
* Run `cargo build --release`. The executable can be found in `<project path>/target/release`.
