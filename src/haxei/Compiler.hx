package haxei;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.MacroType;
import haxe.macro.Tools;
import haxe.macro.Type;
#end
import haxe.ds.StringMap in Hash;

/*
 * haxei compile-time type registration
 * Copyright (c) 2012 Jonas Malaco Filho
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 
class Compiler {

	#if macro
	
	// 
	/*
	 * 
	 * Adapted from haxe.macro.Compiler.include
	 * Copyright (c) 2005-2010, The haXe Project Contributors
	 * All rights reserved.
	 * Redistribution and use in source and binary forms, with or without
	 * modification, are permitted provided that the following conditions are met:
	 *
	 *   - Redistributions of source code must retain the above copyright
	 *     notice, this list of conditions and the following disclaimer.
	 *   - Redistributions in binary form must reproduce the above copyright
	 *     notice, this list of conditions and the following disclaimer in the
	 *     documentation and/or other materials provided with the distribution.
	 *
	 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
	 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
	 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
	 * DAMAGE.
	 */
	public static function register( pack : String, ?rec = true, ?ignore : Array<String>, ?classPaths : Array<String> ) : Void {
		var skip = null == ignore ?	function(c) return false : function(c) return Lambda.has(ignore, c);
		if(null == classPaths)
			classPaths = Context.getClassPath();
		#if HAXEI_DEBUG
		trace( 'Class paths: ' + classPaths );
		#end
		// normalize class path
		for( i in 0...classPaths.length ) {
			var cp = StringTools.replace(classPaths[i], "\\", "/");
			if(StringTools.endsWith(cp, "/"))
				cp = cp.substr(0, -1);
			classPaths[i] = cp;
		}
		var prefix = pack == '' ? '' : pack + '.';
		for( cp in classPaths ) {
			#if HAXEI_DEBUG
			trace( 'At class path ' + cp );
			#end
			var path = pack == '' ? cp : cp + "/" + pack.split(".").join("/");
			if( !sys.FileSystem.exists(path) || !sys.FileSystem.isDirectory(path) || skip( pack ) )
				continue;
			for( file in sys.FileSystem.readDirectory(path) ) {
				if( StringTools.endsWith(file, ".hx") ) {
					var cl = prefix + file.substr(0, file.length - 3);
					if( skip(cl) )
						continue;
					include_module( cl );
				} else if( rec && sys.FileSystem.isDirectory(path + "/" + file) && !skip(prefix + file) )
					register( prefix + file, true, ignore, classPaths );
			}
		}
	}

	public static var registred : Hash<EType> = { new Hash(); };
	
	static function include_module( module : String ) : Void {
		for ( type in Context.getModule( module ) )
			add( type );
	}
	
	static function add( type : Type ) {
		var r = ~/(.+)\..+/;
		switch ( type ) {
			case TEnum( t, params ) : cast t.get();
				var config = t.get();
				if ( !config.isPrivate ) {
					var name = r.match( config.module ) ? r.matched( 1 ) + '.' + config.name : config.name;
					registred.set( name, TEnum( name ) );
				}
			case TInst( t, params ) : cast t.get();
				var config = t.get();
				if ( !config.isPrivate ) {
					var name = r.match( config.module ) ? r.matched( 1 ) + '.' + config.name : config.name;
					registred.set( name, TClass( name ) );
				}
			case TAbstract( t, params ) : 
				// Ignore for now
			case TType( t, params ) :
				var config = t.get();
				if ( !config.isPrivate ) {
					var name = r.match( config.module ) ? r.matched( 1 ) + '.' + config.name : config.name;
					registred.set( name, TType( name ) );
					add( Context.follow( type, true ) );
				}
			case TFun( args, ret ) : // do nothing
			case TAnonymous( a ) : // do nothing
			case TDynamic( t ) : // do nothing
			default : throw 'Did not expect ' + type ;
		}
	}
	
	#end
	
}

#if macro
private enum EType {
	TClass( name : String );
	TEnum( name : String );
	TType( name : String );
}
#end
