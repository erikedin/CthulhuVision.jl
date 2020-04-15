module Rendering

export render

using CuArrays, CUDAnative

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image

@inline function hitsphere(center::Vec3, radius::Float32, ray::Ray) :: Float32
    oc = origin(ray) - center
    a = dot(direction(ray), direction(ray))
    b = 2.0f0 * dot(oc, direction(ray))
    c = dot(oc, oc) - radius*radius
    discriminant = b*b - 4.0f0*a*c
    
    if discriminant < 0.0f0
        -1.0f0
    else
        (-b - CUDAnative.sqrt(discriminant)) / (2.0f0*a)
    end
end

@inline function color(r::Ray) :: RGB
    t = hitsphere(Vec3(0.0f0, 0.0f0, -1.0f0), 0.5f0, r)
    if t > 0.0f0
        n = unit(pointat(r, t) - Vec3(0.0f0, 0.0f0, -1.0f0))
        return 0.5f0*RGB(n.x + 1.0f0, n.y + 1.0f0, n.z + 1.0f0)
    end
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