module Materials

export HitRecord, Material, Scatter, scatter, lambertian, metal, dielectric

using CUDAnative
using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Light

struct Material
    albedo      :: RGB
    fuzz        :: Float32
    plambert    :: Float32
    pmetal      :: Float32
    pdielectric :: Float32
    refindex    :: Float32
end

@inline nomaterial() = Material(RGB(0.0f0, 0.0f0, 0.0f0), 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0)
@inline lambertian(albedo::RGB) = Material(albedo, 0.0f0, 1.0f0, 0.0f0, 0.0f0, 0.0f0)
@inline metal(albedo::RGB, fuzz :: Float32 = 0.0f0) = Material(albedo, fuzz, 0.0f0, 1.0f0, 0.0f0, 0.0f0)
@inline dielectric(refindex::Float32) = Material(RGB(0.0f0, 0.0f0, 0.0f0), 0.0f0, 0.0f0, 0.0f0, 1.0f0, refindex)

struct Scatter
    ray::Ray
    attenuation::RGB
    isreflected::Bool
end

struct Refract
    ray::Vec3
    isrefracted::Bool
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

@inline function refract(v::Vec3, normal::Vec3, niovernt::Float32) :: Refract
    uv = unit(v)
    dt = dot(uv, normal)
    discriminant = 1.0f0 - niovernt * niovernt * (1.0f0 - dt*dt)
    if discriminant > 0.0f0
        ray = niovernt * (uv - dt * normal) - CUDAnative.sqrt(discriminant) * normal
        Refract(ray, true)
    else
        Refract(Vec3(0.0f0, 0.0f0, 0.0f0), false)
    end
end

@inline function scattermetal(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    reflected = reflect(unit(direction(ray)), rec.normal)
    scattered = Ray(rec.p, reflected + rec.material.fuzz * randominunitsphere(rng))
    isreflected = dot(direction(scattered), rec.normal) > 0.0f0

    Scatter(scattered, rec.material.albedo, isreflected)
end

@inline function scatterdielectric(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    reflected = reflect(direction(ray), rec.normal)
    attenuation = RGB(1.0f0, 1.0f0, 1.0f0)

    outwardnormal, niovernt = if dot(direction(ray), rec.normal) > 0.0f0
        -rec.normal, rec.material.refindex
    else
        rec.normal, 1.0f0 / rec.material.refindex
    end

    refracted = refract(direction(ray), outwardnormal, niovernt)
    scattered = if refracted.isrefracted
        Ray(rec.p, refracted.ray)
    else
        Ray(rec.p, reflected)
    end

   Scatter(scattered, attenuation, true)
end

@inline function scatter(ray::Ray, rec::HitRecord, rng::UniformRNG) :: Scatter
    materialprob = next(rng)

    if materialprob <= rec.material.plambert
        scatterlambert(ray, rec, rng)
    elseif materialprob <= rec.material.pmetal
        scattermetal(ray, rec, rng)
    else
        scatterdielectric(ray, rec, rng)
    end
end

end