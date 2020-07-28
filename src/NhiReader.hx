package ;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesInput;

/**
 * ...
 * @author YellowAfterlife
 */
class NhiReader {
	public var format:Int;
	public var width:Int;
	public var height:Int;
	public var palette:Vector<Int>;
	public var meta:String = "empty input";
	public var pixels:Bytes;
	public static var defPalette:NhiPalette = {
		var pal = new Vector(256);
		for (i in 0 ... 256) {
			pal[i] = i | (i << 8) | (i << 16) | (255 << 24);
		};
		pal;
	};
	
	private static function sizeStr(len:Int):String {
		return Std.string(Math.ffloor(len / 1024 * 100) / 100) + "KB";
	}
	public function new() {
		//
	}
	public function read(bytes:Bytes, ?pal:NhiPalette) {
		if (pal == null) pal = defPalette;
		
		var reader = new BytesInput(bytes);
		meta = "empty input";
		format = reader.readUInt16();
		meta = 'format $format; ' + sizeStr(bytes.length);
		
		switch (format) {
			case 18: { // *some* palette
				width = reader.readUInt16();
				height = reader.readUInt16();
				palette = defPalette;
			};
			case 22: { // *some* palette and some meta
				width = reader.readUInt16();
				height = reader.readUInt16();
				reader.readInt32(); // ???
				palette = defPalette;
			};
			case 19, 23, 27: { // probably compressed, don't read well
				width = reader.readUInt16();
				height = reader.readUInt16();
				palette = defPalette;
				meta += "; mystery";
			};
			case 26: { // inline RGB(255-A) palette
				width = reader.readUInt16();
				height = reader.readUInt16();
				palette = new Vector(256);
				for (i in 0 ... 256) {
					var c = reader.readInt32();
					c = ((255 - (c >> 24)) << 24) | (c & 0xFFFFFF);
					palette[i] = c;
				}
			};
			default: throw "Unknown format";
		}
		meta += '; ${width}x$height';
		//
		pixels = Bytes.alloc(width * height * 4);
		readPixels(reader);
	}
	private function readPixels(reader:BytesInput) {
		var avail = reader.length - reader.position;
		var pos = 0;
		for (y in 0 ... height)
		for (x in 0 ... width) {
			if (avail-- <= 0) {
				meta += "; hit EOF";
				return;
			}
			var ind = reader.readByte();
			pixels.setInt32(pos, palette[ind]);
			pos += 4;
		}
		if (avail > 0) meta += '; ${sizeStr(avail)} trailing data';
	}
}