using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering
using CthulhuVision.Camera
using CthulhuVision.Spheres
using CthulhuVision.Scenes
using CthulhuVision.Random

width = 200
height = 100
image = PPM(Dimension(width, height))

brown = lambertian(RGB(0.4f0, 0.2f0, 0.1f0))
shiny = metal(RGB(0.7f0, 0.6f0, 0.5f0))
grey  = lambertian(RGB(0.5f0, 0.5f0, 0.5f0))
light = dielectric(1.0f0; emission = RGB(1.0f0, 1.0f0, 1.0f0))

world = Vector{Sphere}([
    Sphere(Vec3( 0.0f0, -1000.0f0, 0.0f0), 1000.0f0, grey),
    Sphere(Vec3( 0.0f0,   100.0f0, 0.0f0),   50.0f0, light),
    Sphere(Vec3( 0.0f0,     1.0f0, 0.0f0),    1.0f0, dielectric(1.5f0)),
    Sphere(Vec3(-4.0f0,     1.0f0, 0.0f0),    1.0f0, brown),
    Sphere(Vec3( 4.0f0,     1.0f0, 3.0f0),    1.0f0, shiny),
])

rng = uniformfromindex(0)

for a = -11:10
    for b = -11:10
        for c = 1:2
            radius = 0.005f0
            choosematerial = next(rng)
            center = Vec3(Float32(a) + next(rng), radius, b + next(rng))
            if lenhost(center - Vec3(4.0f0, 0.2f0, 0.0f0)) > 0.2f0
                material = if choosematerial < 0.8
                    lambertian(RGB(next(rng) * next(rng), next(rng) * next(rng), next(rng) * next(rng)))
                elseif choosematerial < 0.95
                    metal(RGB(0.5f0 * (1.0f0 + next(rng)), 0.5f0 * (1.0f0 + next(rng)), 0.5f0 * (1.0f0 + next(rng))))
                else
                    dielectric(1.5f0)
                end
                sphere = Sphere(center, radius, material)
                push!(world, sphere)
            end
        end
    end
end

transforms = [
    identitytransform(),
]
instances = [
    Instance(i, 1) for i = 1:length(world)
]

aspect = Float32(image.dimension.width / image.dimension.height)
vfov = 20.0f0

lookfrom = Vec3(13.0f0, 2.0f0, 3.0f0)
lookat = Vec3(0.0f0, 0.0f0, 0.0f0)
vup = Vec3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.1f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

ambientemission = RGB(0.02f0, 0.02f0, 0.1f0)
settings = SceneSettings(ambientemission)
scene = Scene(world, transforms, instances, settings)

render(image, camera, scene)

saveimage(image, examplefilename("instancing1"))

