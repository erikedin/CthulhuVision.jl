module Rendering

export render

using CuArrays, CUDAnative

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image

@inline function color(r::Ray) :: RGB
    unitdirection = unit(direction(r))
    t = 0.5f0 * (unitdirection.y + 1.0f0)
    vec = (1.0f0 - t)*Vec3(1.0f0, 1.0f0, 1.0f0) + t*Vec3(0.5f0, 0.7f0, 1.0f0)
    RGB(vec.x, vec.y, vec.z)
end

function gpurender(a, width, height)
    y = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    x = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    if x < width && y < height
        lowerleft  = Vec3(-2.0f0, -1.0f0, -1.0f0)
        horizontal = Vec3( 4.0f0,  0.0f0,  0.0f0)
        vertical   = Vec3( 0.0f0,  2.0f0,  0.0f0)
        origin     = Vec3( 0.0f0,  0.0f0,  0.0f0)

        u = Float32(x / width)
        v = Float32(y / height)
        ray = Ray(origin, lowerleft + u*horizontal + v*vertical)
        c = color(ray)

        @inbounds a[y, x] = c
    end

    return nothing
end

function render(image::PPM)
    CuArrays.@allowscalar false

    pixels = CuArray{RGB}(undef, image.dimension.height, image.dimension.width)

    blocks = ceil(Int, image.dimension.height / 16), ceil(Int, image.dimension.width / 16)

    CuArrays.@sync begin
        @cuda threads=(16, 16) blocks=blocks gpurender(pixels, image.dimension.width, image.dimension.height)
    end

    for y = 0:image.dimension.height-1, x = 0:image.dimension.width-1
        px = Pixel(x, y)
        cpuarray = Array(pixels)
        c = cpuarray[y + 1, x + 1]

        pixel(image, px, c)
    end
end

end