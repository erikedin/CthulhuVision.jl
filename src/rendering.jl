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
using CthulhuVision.Scenes
using CthulhuVision.Worlds
using CthulhuVision.BVH

@inline function color(r::Ray, world, settings::SceneSettings, rng::UniformRNG) :: RGB
    maxbounces = 50

    attenuation = RGB(1.0f0, 1.0f0, 1.0f0)
    result = RGB(0.0f0, 0.0f0, 0.0f0)
    ray = r

    for i = 1:maxbounces
        rec = hit(world, 0.001f0, typemax(Float32), ray)

        if rec.ishit
            scattered = scatter(ray, rec, rng)
            if !scattered.isreflected
                break
            end

            attenuation = attenuation * scattered.attenuation
            result += rec.material.emission * attenuation
            ray = scattered.ray
        else
            result += attenuation * settings.ambientemission
            break
        end
    end

    result
end

@inline function makeprng() :: UniformRNG
    index = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    uniformfromindex(index)
end

function gpurender(a, camera, width, height, scenesettings, world, bvh)
    y = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    x = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    bvhworld = BVHWorld(bvh, world)

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
            col = col + color(ray, bvhworld, scenesettings, rng)
        end

        col /= Float32(nsamples)

        @inbounds a[y, x] = col
    end

    return nothing
end

function render(image::PPM, camera, scene::Scene)
    CuArrays.@allowscalar false

    world = buildworld(scene)

    pixels = CuArray{RGB}(undef, image.dimension.height, image.dimension.width)
    world_d = CuArray{Sphere}(world.objects)

    blocks = ceil(Int, image.dimension.height / 16), ceil(Int, image.dimension.width / 16)
    threads = (16, 16)

    rng = uniformfromindex(0)
    bvh = bvhbuilder(world, rng)

    bvh_d = CuArray{BVHNode}(bvh)

    CuArrays.@sync begin
        @cuda threads=threads blocks=blocks gpurender(pixels, camera, image.dimension.width, image.dimension.height, scene.settings, world_d, bvh_d)
    end

    cpuarray = Array{RGB, 2}(pixels)
    for y = 0:image.dimension.height-1, x = 0:image.dimension.width-1
        px = Pixel(x, y)
        c = cpuarray[y + 1, x + 1]

        pixel(image, px, c)
    end
end

end