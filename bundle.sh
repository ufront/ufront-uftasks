#!/bin/sh

libname='ufront-uftasks'
rm -f "${libname}.zip"
zip -r "${libname}.zip" haxelib.json src LICENSE.txt README.md
echo "Saved as ${libname}.zip. Please run git tag"
