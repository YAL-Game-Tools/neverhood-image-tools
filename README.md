# neverhood-image-tools
Hello!

This is a small tool that lets you work with image files from [The Neverhood](https://en.wikipedia.org/wiki/The_Neverhood).

You'll need to extract your images from the BLB package first.

Here's what it can do, depending on file you give it:

* NHI: Converts a Neverhood image file to PNG.  
  Format 26 is best supported, some formats require a valid palette, some are compressed (?) and don't load correctly.
* NHP: Loads a Neverhood palette file and uses it for subsequent image files that do not have a built-in palette.  
  Reloads the last loaded image with this palette, if any.
* PNG/BMP: Converts a regular image to format-26 Neverhood image.  
  If your image has >256 colors, extra colors will be discarded using a very poorly written algoirthm.

Credits:

* Tool by [YellowAfterlife](https://yal.cc/).
* Written in [Haxe](https://haxe.org/).
* Vaguely based on "nhi2bmp" 0.1.2 by Max Ivanoff.
