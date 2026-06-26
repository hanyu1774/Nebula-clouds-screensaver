#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct StarVertex {
    pub position: [f32; 3],
    pub normal: [f32; 3],
}

pub const STAR_VERTICES: [StarVertex; 12] = [
    StarVertex {
        position: [0.9992, -1.3753, 0.0],
        normal: [0.5878, -0.8090, 0.0],
    }, // 0: lower-right outer tip
    StarVertex {
        position: [0.0000, -0.8800, 0.0],
        normal: [0.0000, -1.0000, 0.0],
    }, // 1: bottom inner
    StarVertex {
        position: [0.0000, 0.0000, -0.55],
        normal: [0.0000, 0.0000, -1.0],
    }, // 2: back peak
    StarVertex {
        position: [0.8373, -0.2719, 0.0],
        normal: [0.9511, -0.3090, 0.0],
    }, // 3: lower-right inner
    StarVertex {
        position: [0.0000, 0.0000, 0.55],
        normal: [0.0000, 0.0000, 1.0],
    }, // 4: front peak
    StarVertex {
        position: [1.6168, 0.5253, 0.0],
        normal: [0.9511, 0.3090, 0.0],
    }, // 5: upper-right outer tip
    StarVertex {
        position: [-0.9992, -1.3753, 0.0],
        normal: [-0.5878, -0.8090, 0.0],
    }, // 6: lower-left outer tip
    StarVertex {
        position: [-0.8373, -0.2719, 0.0],
        normal: [-0.9511, -0.3090, 0.0],
    }, // 7: lower-left inner
    StarVertex {
        position: [-1.6168, 0.5253, 0.0],
        normal: [-0.9511, 0.3090, 0.0],
    }, // 8: upper-left outer tip
    StarVertex {
        position: [0.5173, 0.7119, 0.0],
        normal: [0.5878, 0.8090, 0.0],
    }, // 9: upper-right inner
    StarVertex {
        position: [0.0000, 1.7000, 0.0],
        normal: [0.0000, 1.0000, 0.0],
    }, // 10: top outer tip
    StarVertex {
        position: [-0.5173, 0.7119, 0.0],
        normal: [-0.5878, 0.8090, 0.0],
    }, // 11: upper-left inner
];

pub const STAR_INDICES: [u16; 60] = [
    0, 1, 2, 3, 0, 2, 0, 4, 1, 3, 4, 0, 3, 2, 5, 3, 5, 4, 6, 4, 7, 1, 4, 6, 7, 4, 8, 4, 9, 10, 11,
    4, 10, 5, 9, 4, 8, 4, 11, 1, 6, 2, 6, 7, 2, 7, 8, 2, 8, 11, 2, 11, 10, 2, 5, 2, 9, 2, 10, 9,
];

/*
#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct StarVertex {
    position: [f32; 3],
    normal: [f32; 3],
}

pub const STAR_VERTICES: [StarVertex; 12] = [
    StarVertex {
        position: [1.1998, -1.3929, -0.0450],
        normal: [0.6751, -0.7377, -0.0037],
    },
    StarVertex {
        position: [0.0113, -0.9455, -0.0466],
        normal: [0.0033, -0.9999, -0.0105],
    },
    StarVertex {
        position: [0.0116, -0.0852, -0.5966],
        normal: [0.0031, 0.0283, -0.9996],
    },
    StarVertex {
        position: [0.9225, -0.3998, -0.0389],
        normal: [0.9840, -0.1783, -0.0007],
    },
    StarVertex {
        position: [0.0071, -0.0934, 0.5221],
        normal: [-0.0052, 0.0138, 0.9999],
    },
    StarVertex {
        position: [1.6145, 0.3892, -0.0302],
        normal: [0.9385, 0.3453, 0.0052],
    },
    StarVertex {
        position: [-1.1689, -1.3981, -0.0548],
        normal: [-0.6707, -0.7417, -0.0093],
    },
    StarVertex {
        position: [-0.8961, -0.4038, -0.0464],
        normal: [-0.9833, -0.1819, -0.0089],
    },
    StarVertex {
        position: [-1.5916, 0.3821, -0.0436],
        normal: [-0.9399, 0.3415, -0.0026],
    },
    StarVertex {
        position: [0.6081, 0.4807, -0.0337],
        normal: [0.4333, 0.9012, 0.0049],
    },
    StarVertex {
        position: [0.0060, 1.3981, -0.0295],
        normal: [-0.0039, 1.0000, 0.0060],
    },
    StarVertex {
        position: [-0.5856, 0.4781, -0.0387],
        normal: [-0.4413, 0.8973, 0.0012],
    },
];

pub const STAR_INDICES: [u16; 60] = [
    0, 1, 2, 3, 0, 2, 0, 4, 1, 3, 4, 0, 3, 2, 5, 3, 5, 4, 6, 4, 7, 1, 4, 6, 7, 4, 8, 4, 9, 10, 11,
    4, 10, 5, 9, 4, 8, 4, 11, 1, 6, 2, 6, 7, 2, 7, 8, 2, 8, 11, 2, 11, 10, 2, 5, 2, 9, 2, 10, 9,
];
*/
