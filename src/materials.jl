module Materials

export HitRecord, Material, Scatter, scatter

using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Light

struct Material
    albedo::RGB
end

struct Scatter
    ray::Ray
    attenuation::RGB
    isreflected::Bool
end

struct HitRecord
    t::Float32
    p::Vec3
    normal::Vec3
    ishit::Bool
    material::Material

    HitRecord() = new(
        typemax(Float32),
        Vec3(0.0f0, 0.0f0, 0.0f0),
        Vec3(0.0f0, 0.0f0, 0.0f0),
        false,
        Material(RGB(0.0f0, 0.0f0, 0.0f0)))
    HitRecord(t::Float32, p::Vec3, normal::Vec3, material::Material) = new(t, p, normal, true, material)
end

@inline function scatter(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    target = rec.p + rec.normal + randominunitsphere(rng)
    scattered = Ray(rec.p, target - rec.p)
    
    Scatter(scattered, rec.material.albedo, true)
end

end