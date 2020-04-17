module Camera

export SimpleCamera, getray

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

end