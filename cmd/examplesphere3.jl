using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering

width = 400
height = 200
image = PPM(Dimension(width, height))

greenmaterial = Material(RGB(0.8f0, 0.8f0, 0.0f0))

world = Vector{Sphere}([
    Sphere(Vec3(0.0f0, 0.0f0, -1.0f0), 0.5f0, greenmaterial),
    Sphere(Vec3(0.0f0, -100.5f0, -1.0f0), 100.0f0, greenmaterial),
])
render(image, world)

saveimage(image, examplefilename("sphere2"))