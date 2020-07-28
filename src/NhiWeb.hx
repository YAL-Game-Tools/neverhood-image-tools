package ;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.Path;
import js.Browser.document;
import js.html.AnchorElement;
import js.html.CanvasElement;
import js.html.DragEvent;
import js.html.Element;
import js.html.Event;
import js.html.File;
import js.html.FormElement;
import js.html.ImageData;
import js.html.InputElement;
import js.html.InputEvent;
import js.lib.ArrayBuffer;
import js.lib.Uint8ClampedArray;
import js.html.FileReader;

/**
 * ...
 * @author YellowAfterlife
 */
class NhiWeb {
	static var container:Element = document.getElementById("nh-container");
	
	static function createTextEl(text:String, type:String = "span"):Element {
		var el = document.createElement(type);
		el.appendChild(document.createTextNode(text));
		return el;
	}
	static function addTextEl(par:Element, text:String, type:String = "span"):Element {
		var el = createTextEl(text, type);
		par.appendChild(el);
		return el;
	}
	static function addLinkEl(par:Element, text:String, href:String = "javascript:void(0)"):Element {
		var el:AnchorElement = cast addTextEl(par, text, "a");
		el.href = href;
		return el;
	}
	
	static function loadNHI(bytes:Bytes, name:String) {
		var reader = new NhiReader();
		var error:String = null;
		try {
			reader.read(bytes);
		} catch (x:Dynamic) {
			error = "Error: " + x;
		}
		var div = document.createDivElement();
		if (reader.pixels != null) {
			var canv = document.createCanvasElement();
			canv.width = reader.width;
			canv.height = reader.height;
			var ctx = canv.getContext2d();
			var imr = new Uint8ClampedArray(reader.pixels.getData());
			var imd = new ImageData(imr, reader.width, reader.height);
			ctx.putImageData(imd, 0, 0);
			var cdiv = document.createDivElement();
			cdiv.appendChild(canv);
			div.appendChild(cdiv);
		}
		if (error != null) addTextEl(div, error, "div");
		addTextEl(div, name, "div");
		addTextEl(div, "(" + reader.meta + ")", "div");
		container.appendChild(div);
	}
	
	static var lastImageBytes:Bytes = null;
	static var lastImageName:String = "?";
	static function loadFile(file:File) {
		var ext = Path.extension(file.name).toLowerCase();
		switch (ext) {
			case "nhi": {
				var reader = new FileReader();
				reader.onloadend = function(_) {
					var bytes = Bytes.ofData(reader.result);
					lastImageBytes = bytes;
					lastImageName = file.name;
					loadNHI(bytes, file.name);
				};
				reader.readAsArrayBuffer(file);
			};
			case "nhp": {
				var reader = new FileReader();
				reader.onloadend = function(_) {
					var bytes = Bytes.ofData(reader.result);
					var pal = new Vector(256);
					for (i in 0 ... 256) {
						var c = bytes.getInt32(i * 4);
						c = ((255 - (c >> 24)) << 24) | (c & 0xFFFFFF);
						pal[i] = c;
					}
					NhiReader.defPalette = pal;
					var div = document.createDivElement();
					var text = "Palette loaded.";
					addTextEl(div, "Palette loaded.", "div");
					container.appendChild(div);
					if (lastImageBytes != null) {
						addTextEl(div, 'Reloading $lastImageName with this palette...');
						loadNHI(lastImageBytes, lastImageName);
					}
				};
				reader.readAsArrayBuffer(file);
			};
			case "png", "bmp": {
				var reader = new FileReader();
				reader.onloadend = function(_) {
					var img = document.createImageElement();
					img.onload = function(_) {
						var canv = document.createCanvasElement();
						var w = img.width, h = img.height;
						canv.width = w;
						canv.height = h;
						var ctx = canv.getContext2d();
						ctx.drawImage(img, 0, 0);
						var imd = ctx.getImageData(0, 0, w, h);
						var imr = imd.data;
						var buf = imr.buffer.slice(imr.byteOffset, imr.byteOffset + imr.byteLength);
						var bytes = Bytes.ofData(buf);
						var nhi = NhiWriter.write(bytes, w, h);
						var nhiName = Path.withExtension(file.name, "nhi");
						//
						var div = document.createDivElement();
						var imgd = addTextEl(div, "", "div");
						imgd.appendChild(img);
						addTextEl(div, 'Converted this ${w}x$h image to NHI!');
						for (warn in NhiWriter.warnings) addTextEl(div, warn);
						var tools = addTextEl(div, "", "div");
						var download = addLinkEl(tools, "Download");
						download.onclick = function(_) {
							BlobTools.save(nhi, nhiName, "application/octet-stream");
						};
						addTextEl(tools, " · ");
						var view = addLinkEl(tools, "Preview");
						view.onclick = function(_) {
							loadNHI(nhi, nhiName);
						};
						container.appendChild(div);
					};
					img.src = reader.result;
				};
				reader.readAsDataURL(file);
			};
		}
	}
	
	static function initDragAndDrop() {
		function cancelDefault(e:Event) {
			e.preventDefault();
			return false;
		}
		//
		var body = document;
		body.addEventListener("dragover", cancelDefault);
		body.addEventListener("dragenter", cancelDefault);
		body.addEventListener("drop", function(e:DragEvent) {
			e.preventDefault();
			var dt = e.dataTransfer;
			for (file in dt.files) loadFile(file);
			return false;
		});
	}
	static function initFilePicker() {
		var input:InputElement = cast document.getElementById("nh-file-picker");
		var form:FormElement = cast document.getElementById("nh-file-picker-form");
		input.addEventListener("change", function(e:DragEvent) {
			if (input.files != null) {
				for (file in input.files) loadFile(file);
			}
			form.reset();
			return false;
		});
		//
		document.getElementById("nh-clear").addEventListener("click", function(_) {
			container.innerHTML = "";
		});
	}
	public static function main() {
		initDragAndDrop();
		initFilePicker();
	}
}