using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Rendering

width = 200
height = 100
image = PPM(Dimension(width, height))

world = Vector{Sphere}([
    Sphere(Vec3(0.0f0, 0.0f0, -1.0f0), 0.5f0),
    Sphere(Vec3(0.0f0, -100.5f0, -1.0f0), 100.0f0),
])
render(image, world)

saveimage(image, examplefilename("sphere2"))