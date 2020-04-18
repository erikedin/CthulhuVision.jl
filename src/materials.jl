module Materials

export HitRecord, Material, Scatter, scatter, lambertian, metal

using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Light

struct Material
    albedo   :: RGB
    plambert :: Float32
    pmetal   :: Float32
end

@inline nomaterial() = Material(RGB(0.0f0, 0.0f0, 0.0f0), 0.0f0, 0.0f0)
@inline lambertian(albedo::RGB) = Material(albedo, 1.0f0, 0.0f0)
@inline metal(albedo::RGB) = Material(albedo, 0.0f0, 1.0f0)

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
        nomaterial())
    HitRecord(t::Float32, p::Vec3, normal::Vec3, material::Material) = new(t, p, normal, true, material)
end

@inline function scatterlambert(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    target = rec.p + rec.normal + randominunitsphere(rng)
    scattered = Ray(rec.p, target - rec.p)
    
    Scatter(scattered, rec.material.albedo, true)
end

@inline reflect(v::Vec3, n::Vec3) :: Vec3 = v - 2.0f0 * dot(v, n) * n

@inline function scattermetal(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    reflected = reflect(unit(direction(ray)), rec.normal)
    scattered = Ray(rec.p, reflected)
    isreflected = dot(direction(scattered), rec.normal) > 0.0f0

    Scatter(scattered, rec.material.albedo, isreflected)
end

@inline function scatter(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    materialprob = next(rng)

    if materialprob <= rec.material.plambert
        scatterlambert(ray, rec, rng)
    else #if materialprob <= rec.material.pmetal
        scattermetal(ray, rec, rng)
    end
end

end