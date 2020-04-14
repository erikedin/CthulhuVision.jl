using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light

width = 200
height = 100
image = PPM(Dimension(width, height))

lowerleft  = Vec3(-2.0f0, -1.0f0, -1.0f0)
horizontal = Vec3( 4.0f0,  0.0f0,  0.0f0)
vertical   = Vec3( 0.0f0,  2.0f0,  0.0f0)
origin     = Vec3( 0.0f0,  0.0f0,  0.0f0)

function color(r::Ray) :: RGB
    unitdirection = unit(direction(r))
    t = 0.5f0 * (unitdirection.y + 1.0f0)
    vec = (1.0f0 - t)*Vec3(1.0f0, 1.0f0, 1.0f0) + t*Vec3(0.5f0, 0.7f0, 1.0f0)
    RGB(vec.x, vec.y, vec.z)
end

for y = height - 1:-1:0, x = 0:width - 1
    u = Float32(x / width)
    v = Float32(y / height)
    ray = Ray(origin, lowerleft + u*horizontal + v*vertical)
    c = color(ray)

    pixel(image, Pixel(x, y), c)
end

saveimage(image, examplefilename("background"))