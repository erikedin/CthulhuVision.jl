using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering

width = 400
height = 200
image = PPM(Dimension(width, height))

greenmaterial = lambertian(RGB(0.8f0, 0.8f0, 0.0f0))
blue = lambertian(RGB(0.1f0, 0.2f0, 0.5f0))
metal1 = metal(RGB(0.8f0, 0.6f0, 0.2f0), 0.05f0)

world = Vector{Sphere}([
    Sphere(Vec3(0.0f0, 0.0f0, -1.0f0), 0.5f0, blue),
    Sphere(Vec3(0.0f0, -100.5f0, -1.0f0), 100.0f0, greenmaterial),
    Sphere(Vec3(1.0f0, 0.0f0, -1.0f0), 0.5f0, metal1),
    Sphere(Vec3(-1.0f0, 0.0f0, -1.0f0), 0.5f0, dielectric(1.5f0)),
    Sphere(Vec3(-1.0f0, 0.0f0, -1.0f0), -0.45f0, dielectric(1.5f0)),
])
render(image, world)

saveimage(image, examplefilename("camera2"))