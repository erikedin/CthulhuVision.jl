module Camera

export SimpleCamera, FovCamera, getray

using CthulhuVision.Math
using CthulhuVision.Random
using CthulhuVision.Light

struct SimpleCamera
    origin     :: Vec3
    lowerleft  :: Vec3
    horizontal :: Vec3
    vertical   :: Vec3
end

@inline function getray(cam::SimpleCamera, u::Float32, v::Float32, rng::UniformRNG) :: Ray
    direction = cam.lowerleft + u*cam.horizontal + v*cam.vertical - cam.origin
    Ray(cam.origin, direction)
end

@inline unithost(v::Vec3) = 1.0f0 / sqrt(v.x * v.x + v.y * v.y + v.z * v.z) * v

@inline function randominunitdisk(rng::UniformRNG) :: Vec3
    p = Vec3(1.0f0, 1.0f0, 0.0f0)

    while dot(p, p) >= 1.0f0
        p = 2.0f0 * Vec3(next(rng), next(rng), 0.0f0) - Vec3(1.0f0, 1.0f0, 0.0f0)
    end

    p
end

struct FovCamera
    origin     :: Vec3
    lowerleft  :: Vec3
    horizontal :: Vec3
    vertical   :: Vec3
    u          :: Vec3
    v          :: Vec3
    w          :: Vec3
    lensradius :: Float32

    function FovCamera(lookfrom::Vec3, lookat::Vec3, vup::Vec3, vfov::Float32, aspect::Float32, aperture::Float32, focusdist::Float32)
        lensradius = aperture / 2.0f0
        theta = vfov * pi / 180.0f0
        halfheight = tan(theta / 2.0f0)
        halfwidth = aspect * halfheight

        origin = lookfrom
        w = unithost(lookfrom - lookat)
        u = unithost(cross(vup, w))
        v = cross(w, u)

        lowerleft  = origin - halfwidth * focusdist * u - halfheight * focusdist * v - focusdist * w
        horizontal = 2.0f0 * halfwidth * focusdist * u
        vertical   = 2.0f0 * halfheight * focusdist * v

        new(origin, lowerleft, horizontal, vertical, u, v, w, lensradius)
    end
end

@inline function getray(cam::FovCamera, s::Float32, t::Float32, rng::UniformRNG) :: Ray
    rd = cam.lensradius * randominunitdisk(rng)
    offset = rd.x * cam.u + rd.y * cam.v
    direction = cam.lowerleft + s*cam.horizontal + t*cam.vertical - cam.origin - offset
    Ray(cam.origin + offset, direction)
end

end