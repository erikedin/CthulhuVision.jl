module Rendering

export render, RenderSettings

using CuArrays, CUDAnative

using CthulhuVision.Random
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image
using CthulhuVision.Camera
using CthulhuVision.Materials
using CthulhuVision.Triangles
using CthulhuVision.Scenes

@inline function hit(objects::CuDeviceArray{Triangle, 1, CUDAnative.AS.Global}, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    rec = HitRecord()

    for o in objects
        r = hittriangle(o, tmin, tmax, ray)

        if r.ishit && r.t < rec.t
            rec = r
        end
    end

    rec
end

@inline function color(r::Ray, objects::CuDeviceArray{Triangle, 1, CUDAnative.AS.Global}, settings::SceneSettings, rng::UniformRNG) :: RGB
    maxbounces = 50

    attenuation = RGB(1.0f0, 1.0f0, 1.0f0)
    result = RGB(0.0f0, 0.0f0, 0.0f0)
    ray = r

    for i = 1:maxbounces
        rec = hit(objects, 0.001f0, typemax(Float32), ray)

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

struct RenderSettings
    nsamples::UInt32
end

function gpurender(a, camera, width, height, scenesettings, rendersettings::RenderSettings, objects)
    y = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    x = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    rng = makeprng()

    if x <= width && y <= height
        col = RGB(0.0f0, 0.0f0, 0.0f0)

        for s = 1:rendersettings.nsamples
            dx = next(rng)
            dy = next(rng)
            u = Float32((x + dx) / width)
            v = Float32((y + dy) / height)
            ray = getray(camera, u, v, rng)
            col = col + color(ray, objects, scenesettings, rng)
        end

        col /= Float32(rendersettings.nsamples)

        @inbounds a[y, x] = col
    end

    return nothing
end

function render(image::PPM, camera, scene::Scene, rendersettings::RenderSettings)
    CuArrays.@allowscalar false

    pixels = CuArray{RGB}(undef, image.dimension.height, image.dimension.width)
    objects_d = CuArray{Triangle}(scene.objects)

    blocks = ceil(Int, image.dimension.height / 16), ceil(Int, image.dimension.width / 16)
    threads = (16, 16)

    CuArrays.@sync begin
        @cuda threads=threads blocks=blocks gpurender(pixels, camera, image.dimension.width, image.dimension.height, scene.settings, rendersettings, objects_d)
    end

    cpuarray = Array{RGB, 2}(pixels)
    for y = 0:image.dimension.height-1, x = 0:image.dimension.width-1
        px = Pixel(x, y)
        c = cpuarray[y + 1, x + 1]

        pixel(image, px, c)
    end
end

end