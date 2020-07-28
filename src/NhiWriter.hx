package ;
import haxe.ds.Map;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

/**
 * ...
 * @author YellowAfterlife
 */
class NhiWriter {
	public static var warnings:Array<String> = null;
	static function colDist(a:Int, b:Int) {
		var ad = ((a >> 24) & 0xFF) - ((b >> 24) & 0xFF);
		var rd = ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
		var gd = ((a >>  8) & 0xFF) - ((b >>  8) & 0xFF);
		var bd = ((a >>  0) & 0xFF) - ((b >>  0) & 0xFF);
		return rd * rd + gd * gd + bd * bd + ad * ad;
	}
	static function write26(pixels:Bytes, width:Int, height:Int) {
		var count = width * height;
		//
		var palMap = new Map<Int, NhiPaletteItem>();
		var palList:Array<NhiPaletteItem> = [];
		for (i in 0 ... count) {
			var c = pixels.getInt32(i * 4);
			var palItem = palMap[c];
			if (palItem == null) {
				palItem = new NhiPaletteItem(c);
				palMap[c] = palItem;
				palList.push(palItem);
			}
			palItem.uses++;
		}
		//
		palList.sort(function(a, b) {
			return b.uses - a.uses;
		});
		for (i in 0 ... palList.length) {
			var item = palList[i];
			if (i < 256) { // fits!
				item.index = i;
			} else { // find the nearest color that fits!
				var bestIndex = 0;
				var bestDist = 256 * 256 * 4;
				var myCol = item.color;
				for (k in 0 ... 256) {
					var dist = colDist(myCol, palList[k].color);
					if (dist < bestDist) { bestIndex = k; bestDist = dist; }
				}
				item.index = bestIndex;
			}
		}
		//
		var out = Bytes.alloc(width * height + 6 + 256 * 4);
		out.setUInt16(0, 26);
		out.setUInt16(2, width);
		out.setUInt16(4, height);
		
		// write palette:
		var palLength = palList.length;
		if (palLength > 256) {
			warnings.push('Image has too many colors ($palLength>256)!');
			palLength = 256;
		}
		for (i in 0 ... palLength) {
			var c = palList[i].color;
			c = ((255 - (c >> 24)) << 24) | (c & 0xFFFFFF);
			out.setInt32(6 + i * 4, c);
		}
		
		// write indexed pixels:
		for (i in 0 ... count) {
			var c = pixels.getInt32(i * 4);
			var palItem = palMap[c];
			out.set((6 + 256 * 4) + i, palItem.index);
		}
		
		//
		return out;
	}
	public static function write(pixels:Bytes, width:Int, height:Int, format:Int = 26):Bytes {
		warnings = [];
		switch (format) {
			case 26: return write26(pixels, width, height);
			default: throw "Format not supported!";
		}
	}
}
class NhiPaletteItem {
	public var color:Int;
	public var index:Int = -1;
	public var uses:Int = 0;
	public function new(col:Int) {
		color = col;
	}
}