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

struct FovCamera
    origin     :: Vec3
    lowerleft  :: Vec3
    horizontal :: Vec3
    vertical   :: Vec3

    function FovCamera(vfov::Float32, aspect::Float32)
        theta = vfov * pi / 180.0f0
        halfheight = tan(theta / 2.0f0)
        halfwidth = aspect * halfheight

        lowerleft = Vec3(-halfwidth, -halfheight, -1.0f0)
        horizontal = Vec3(2.0f0*halfwidth, 0.0f0, 0.0f0)
        vertical = Vec3(0.0f0, 2.0f0 * halfheight, 0.0f0)
        origin = Vec3(0.0f0, 0.0f0, 0.0f0)

        new(origin, lowerleft, horizontal, vertical)
    end
end

function getray(cam::FovCamera, u::Float32, v::Float32) :: Ray
    direction = cam.lowerleft + u*cam.horizontal + v*cam.vertical - cam.origin
    Ray(cam.origin, direction)
end

end