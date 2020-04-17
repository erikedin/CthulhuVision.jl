module Rendering

export render, Sphere

using CuArrays, CUDAnative

using CthulhuVision.Random
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image
using CthulhuVision.Camera

struct HitRecord
    t::Float32
    p::Vec3
    normal::Vec3
    ishit::Bool

    HitRecord() = new(typemax(Float32), Vec3(0.0f0, 0.0f0, 0.0f0), Vec3(0.0f0, 0.0f0, 0.0f0), false)
    HitRecord(t::Float32, p::Vec3, normal::Vec3) = new(t, p, normal, true)
end

struct Sphere
    center::Vec3
    radius::Float32
end

@inline function hit(sphere::Sphere, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    oc = origin(ray) - sphere.center
    a = dot(direction(ray), direction(ray))
    b = dot(oc, direction(ray))
    c = dot(oc, oc) - sphere.radius*sphere.radius
    discriminant = b*b - a*c
    
    if discriminant > 0.0f0
        t = (-b - CUDAnative.sqrt(b*b - a*c)) / a
        if t < tmax && t > tmin
            p = pointat(ray, t)
            # TODO: This should in principle be
            #   unit(rec.p - sphere.center)
            # but that will bite me in the ass later when a trick requires
            # the radius to be negative here.
            normal = (p - sphere.center) / sphere.radius
            return HitRecord(t, p, normal)
        end

        t = (-b + CUDAnative.sqrt(b*b - a*c)) / a
        if t < tmax && t > tmin
            p = pointat(ray, t)
            # Same here. Ass-biting.
            normal = (p - sphere.center) / sphere.radius
            return HitRecord(t, p, normal)
        end
    end
    
    HitRecord()
end

@inline function hit(spheres::AbstractVector{Sphere}, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    rec = HitRecord()

    for sphere in spheres
        srec = hit(sphere, tmin, rec.t, ray)
        if srec.ishit
            rec = srec
        end
    end

    rec
end

@inline function color(r::Ray, spheres::AbstractVector{Sphere}, rng::UniformRNG) :: RGB
    maxbounces = 50

    factor = 1.0f0
    result = RGB(0.0f0, 0.0f0, 0.0f0)
    ray = r

    for i = 1:maxbounces
        rec = hit(spheres, 0.001f0, typemax(Float32), ray)

        if rec.ishit
            target = rec.p + rec.normal + randominunitsphere(rng)
            ray = Ray(rec.p, target - rec.p)
            factor *= 0.5f0
        else
            unitdirection = unit(direction(r))
            t = 0.5f0 * (unitdirection.y + 1.0f0)
            vec = (1.0f0 - t)*Vec3(1.0f0, 1.0f0, 1.0f0) + t*Vec3(0.5f0, 0.7f0, 1.0f0)
            result = result + factor * RGB(vec.x, vec.y, vec.z)
            break
        end
    end

    result
end

@inline function makeprng() :: UniformRNG
    index = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    seedgen = SplitMix64(index)
    s0 = next(seedgen)
    s1 = next(seedgen)
    s2 = next(seedgen)
    s3 = next(seedgen)
    UniformRNG(Xoshiro256pp(s0, s1, s2, s3))
end

function gpurender(a, camera::SimpleCamera, width, height, world)
    y = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    x = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    rng = makeprng()

    nsamples = 100

    if x < width && y < height
        col = RGB(0.0f0, 0.0f0, 0.0f0)

        for s = 1:nsamples
            dx = next(rng)
            dy = next(rng)
            u = Float32((x + dx) / width)
            v = Float32((y + dy) / height)
            ray = getray(camera, u, v)
            col = col + color(ray, world, rng)
        end

        col /= Float32(nsamples)

        @inbounds a[y, x] = col
    end

    return nothing
end

function render(image::PPM, world::AbstractVector{Sphere})
    CuArrays.@allowscalar false

    pixels = CuArray{RGB}(undef, image.dimension.height, image.dimension.width)
    world_d = CuArray{Sphere}(world)

    blocks = ceil(Int, image.dimension.height / 16), ceil(Int, image.dimension.width / 16)

    lowerleft  = Vec3(-2.0f0, -1.0f0, -1.0f0)
    horizontal = Vec3( 4.0f0,  0.0f0,  0.0f0)
    vertical   = Vec3( 0.0f0,  2.0f0,  0.0f0)
    origin     = Vec3( 0.0f0,  0.0f0,  0.0f0)
    camera = SimpleCamera(origin, lowerleft, horizontal, vertical)

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