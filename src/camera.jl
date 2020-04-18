module Camera

export SimpleCamera, FovCamera, getray

using CthulhuVision.Math
using CthulhuVision.Light

struct SimpleCamera
    origin     :: Vec3
    lowerleft  :: Vec3
    horizontal :: Vec3
    vertical   :: Vec3
end

function getray(cam::SimpleCamera, u::Float32, v::Float32) :: Ray
    direction = cam.lowerleft + u*cam.horizontal + v*cam.vertical - cam.origin
    Ray(cam.origin, direction)
end

@inline unithost(v::Vec3) = 1.0f0 / sqrt(v.x * v.x + v.y * v.y + v.z * v.z) * v

struct FovCamera
    origin     :: Vec3
    lowerleft  :: Vec3
    horizontal :: Vec3
    vertical   :: Vec3

    function FovCamera(lookfrom::Vec3, lookat::Vec3, vup::Vec3, vfov::Float32, aspect::Float32)
        theta = vfov * pi / 180.0f0
        halfheight = tan(theta / 2.0f0)
        halfwidth = aspect * halfheight

        origin = lookfrom
        w = unithost(lookfrom - lookat)
        u = unithost(cross(vup, w))
        v = cross(w, u)

        lowerleft  = origin - halfwidth * u - halfheight * v - w
        horizontal = 2.0f0 * halfwidth * u
        vertical   = 2.0f0 * halfheight * v

        new(origin, lowerleft, horizontal, vertical)
    end
end

function getray(cam::FovCamera, u::Float32, v::Float32) :: Ray
    direction = cam.lowerleft + u*cam.horizontal + v*cam.vertical - cam.origin
    Ray(cam.origin, direction)
end

end