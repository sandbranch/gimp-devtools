var f = tiled.tilesetFormat("tsx");
var ts = f.read(tiled.scriptArguments[0]);
tiled.log("image=" + ts.image + " size=" + ts.imageWidth + "x" + ts.imageHeight + " tiles=" + ts.tileCount + " status=" + ts.imageStatus);
tiled.log("tilesetFormats: " + tiled.tilesetFormats);
tiled.log("mapFormats: " + tiled.mapFormats);
