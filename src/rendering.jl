module Rendering

export render

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image

function color(r::Ray) :: RGB
    unitdirection = unit(direction(r))
    t = 0.5f0 * (unitdirection.y + 1.0f0)
    vec = (1.0f0 - t)*Vec3(1.0f0, 1.0f0, 1.0f0) + t*Vec3(0.5f0, 0.7f0, 1.0f0)
    RGB(vec.x, vec.y, vec.z)
end

function render(image::PPM)
    lowerleft  = Vec3(-2.0f0, -1.0f0, -1.0f0)
    horizontal = Vec3( 4.0f0,  0.0f0,  0.0f0)
    vertical   = Vec3( 0.0f0,  2.0f0,  0.0f0)
    origin     = Vec3( 0.0f0,  0.0f0,  0.0f0)

    for y = image.dimension.height - 1:-1:0, x = 0:image.dimension.width - 1
        u = Float32(x / image.dimension.width)
        v = Float32(y / image.dimension.height)
        ray = Ray(origin, lowerleft + u*horizontal + v*vertical)
        c = color(ray)

        pixel(image, Pixel(x, y), c)
    end
end

end