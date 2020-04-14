using CthulhuVision.Image
using Dates

image = PPM(Dimension(200, 100))

for x = 0:image.dimension.width-1, y = 0:image.dimension.height-1
    rgb = RGB(Float32(x) / Float32(image.dimension.width),
              Float32(y) / Float32(image.dimension.height),
              0.2f0)
    pixel(image, Pixel(x, y), rgb)
end

saveimage(image, examplefilename("ppm"))