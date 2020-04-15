module Rendering

export render, Sphere

using CuArrays, CUDAnative

using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Image

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

@inline function color(r::Ray, spheres::AbstractVector{Sphere}) :: RGB
    rec = hit(spheres, 0.0f0, typemax(Float32), r)
    if rec.ishit
        0.5f0*RGB(rec.normal.x + 1.0f0, rec.normal.y + 1.0f0, rec.normal.z + 1.0f0)
    else
        unitdirection = unit(direction(r))
        t = 0.5f0 * (unitdirection.y + 1.0f0)
        vec = (1.0f0 - t)*Vec3(1.0f0, 1.0f0, 1.0f0) + t*Vec3(0.5f0, 0.7f0, 1.0f0)
        RGB(vec.x, vec.y, vec.z)
    end
end

function gpurender(a, width, height, world)
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
        c = color(ray, world)

        @inbounds a[y, x] = c
    end

    return nothing
end

function render(image::PPM, world::AbstractVector{Sphere})
    CuArrays.@allowscalar false

    pixels = CuArray{RGB}(undef, image.dimension.height, image.dimension.width)
    world_d = CuArray{Sphere}(world)

    blocks = ceil(Int, image.dimension.height / 16), ceil(Int, image.dimension.width / 16)

    CuArrays.@sync begin
        @cuda threads=(16, 16) blocks=blocks gpurender(pixels, image.dimension.width, image.dimension.height, world_d)
    end

    for y = 0:image.dimension.height-1, x = 0:image.dimension.width-1
        px = Pixel(x, y)
        cpuarray = Array(pixels)
        c = cpuarray[y + 1, x + 1]

        pixel(image, px, c)
    end
end

end