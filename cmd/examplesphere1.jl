using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Rendering

width = 200
height = 100
image = PPM(Dimension(width, height))

render(image)

saveimage(image, examplefilename("sphere1"))