var out = new TextFile("/tmp/claude-1000/leveleditors/test/probe.log", TextFile.Append);
function log(s){ out.writeLine(new Date().toISOString()+" "+s); out.commit(); }
var found = tiled.openAssets.filter(function(a){ return a.isTileset; });
if (found.length == 0) {
  var ts = tiled.open("/tmp/claude-1000/leveleditors/test/g_xcf.tsx");
  log("opened " + ts.imageWidth + "x" + ts.imageHeight + " tiles=" + ts.tileCount);
} else {
  var ts = found[0];
  log("reeval " + ts.imageWidth + "x" + ts.imageHeight + " tiles=" + ts.tileCount + " modified=" + ts.modified);
}
