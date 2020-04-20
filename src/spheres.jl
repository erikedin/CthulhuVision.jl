module Spheres

export Sphere, hit

using CthulhuVision.Math
using CthulhuVision.Materials
using CthulhuVision.Light
using CUDAnative

struct Sphere
    center::Vec3
    radius::Float32
    material::Material
end

@inline function hit(sphere::Sphere, tmin::Float32, tmax::Float32, ray::Ray) :: HitRecord
    @cuprintln("Called sphere hit: Sphere center = ($(sphere.center.x), $(sphere.center.y), $(sphere.center.z)), radius = $(sphere.radius)")
    @cuprintln("tmin = $tmin, tmax = $tmax, ray = ($(ray.a.x), $(ray.a.y), $(ray.a.z)) -> ($(ray.b.x), $(ray.b.y), $(ray.b.z))")
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
            return HitRecord(t, p, normal, sphere.material)
        end

        t = (-b + CUDAnative.sqrt(b*b - a*c)) / a
        if t < tmax && t > tmin
            p = pointat(ray, t)
            # Same here. Ass-biting.
            normal = (p - sphere.center) / sphere.radius
            return HitRecord(t, p, normal, sphere.material)
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

end