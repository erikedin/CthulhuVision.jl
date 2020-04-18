using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering

width = 400
height = 200
image = PPM(Dimension(width, height))

blue = lambertian(RGB(0.0f0, 0.0f0, 1.0f0))
red  = lambertian(RGB(1.0f0, 0.0f0, 0.0f0))

r = cos(pi/4.0f0)
world = Vector{Sphere}([
    Sphere(Vec3(-r, 0.0f0, -1.0f0), r, blue),
    Sphere(Vec3( r, 0.0f0, -1.0f0), r, red),
])
render(image, world)

saveimage(image, examplefilename("camera1"))
