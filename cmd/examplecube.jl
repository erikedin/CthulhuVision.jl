using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering
using CthulhuVision.Camera
using CthulhuVision.Spheres
using CthulhuVision.Random

width = 3840
height = 2160
image = PPM(Dimension(width, height))

brown = lambertian(RGB(0.4f0, 0.2f0, 0.1f0))
shiny = metal(RGB(0.7f0, 0.6f0, 0.5f0))
grey  = lambertian(RGB(0.5f0, 0.5f0, 0.5f0))

world = Vector{Sphere}([
    Sphere(Vec3( 0.0f0, -1000.0f0, 0.0f0), 1000.0f0, grey),
    Sphere(Vec3( 0.0f0,     1.0f0, 0.0f0),    1.0f0, shiny),
    Sphere(Vec3(-4.0f0,     1.0f0, 0.0f0),    1.0f0, dielectric(1.5f0)),
])

rng = uniformfromindex(0)

for a = 1:100
    for b = 1:100
        for c = 1:100
            x = a/100.0f0 - 0.5f0 + 4.0f0
            y = b/100.0f0 + 0.05f0
            z = c/100.0f0
            radius = 0.001f0
            center = Vec3(x, y, z) + 0.005f0 * Vec3(next(rng), next(rng), next(rng))

            # choosematerial = next(rng)
            # material = if choosematerial < 0.1
            #     lambertian(RGB(next(rng) * next(rng), next(rng) * next(rng), next(rng) * next(rng)))
            # elseif choosematerial < 0.95
            #     metal(RGB(0.5f0 * (1.0f0 + next(rng)), 0.5f0 * (1.0f0 + next(rng)), 0.5f0 * (1.0f0 + next(rng))))
            # else
            #     dielectric(1.5f0)
            # end
            sphere = Sphere(center, radius, shiny)
            push!(world, sphere)
        end
    end
end

aspect = Float32(image.dimension.width / image.dimension.height)
vfov = 20.0f0

lookfrom = Vec3(13.0f0, 2.0f0, 3.0f0)
lookat = Vec3(0.0f0, 0.0f0, 0.0f0)
vup = Vec3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.01f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

render(image, camera, world)

saveimage(image, examplefilename("cube"))

