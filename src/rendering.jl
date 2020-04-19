module Rendering

export render

using CuArrays, CUDAnative

using CthulhuVision.Random
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image
using CthulhuVision.Camera
using CthulhuVision.Materials
using CthulhuVision.Spheres

@inline function color(r::Ray, spheres::AbstractVector{Sphere}, rng::UniformRNG) :: RGB
    maxbounces = 50

    attenuation = RGB(1.0f0, 1.0f0, 1.0f0)
    result = RGB(0.0f0, 0.0f0, 0.0f0)
    ray = r

    for i = 1:maxbounces
        rec = hit(spheres, 0.001f0, typemax(Float32), ray)

        if rec.ishit
            scattered = scatter(ray, rec, rng)
            if !scattered.isreflected
                break
            end

            attenuation = attenuation * scattered.attenuation
            ray = scattered.ray
        else
            unitdirection = unit(direction(ray))
            t = 0.5f0 * (unitdirection.y + 1.0f0)
            vec = (1.0f0 - t)*Vec3(1.0f0, 1.0f0, 1.0f0) + t*Vec3(0.5f0, 0.7f0, 1.0f0)
            result = attenuation * RGB(vec.x, vec.y, vec.z)
            break
        end
    end

    result
end

@inline function makeprng() :: UniformRNG
    index = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    uniformfromindex(index)
end

function gpurender(a, camera, width, height, world)
    y = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    x = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    rng = makeprng()

    nsamples = 1000

    if x <= width && y <= height
        col = RGB(0.0f0, 0.0f0, 0.0f0)

        for s = 1:nsamples
            dx = next(rng)
            dy = next(rng)
            u = Float32((x + dx) / width)
            v = Float32((y + dy) / height)
            ray = getray(camera, u, v, rng)
            col = col + color(ray, world, rng)
        end

        col /= Float32(nsamples)

        @inbounds a[y, x] = col
    end

    return nothing
end

function render(image::PPM, camera, world::AbstractVector{Sphere})
    CuArrays.@allowscalar false

    pixels = CuArray{RGB}(undef, image.dimension.height, image.dimension.width)
    world_d = CuArray{Sphere}(world)

    blocks = ceil(Int, image.dimension.height / 16), ceil(Int, image.dimension.width / 16)

    CuArrays.@sync begin
        @cuda threads=(16, 16) blocks=blocks gpurender(pixels, camera, image.dimension.width, image.dimension.height, world_d)
    end

    for y = 0:image.dimension.height-1, x = 0:image.dimension.width-1
        px = Pixel(x, y)
        cpuarray = Array(pixels)
        c = cpuarray[y + 1, x + 1]

        pixel(image, px, c)
    end
end

end