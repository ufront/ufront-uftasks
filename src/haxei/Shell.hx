package haxei;

import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;
import haxe.CallStack;
import haxe.ds.StringMap in Hash;
import haxe.ds.IntMap in IntHash;

#if macro
import haxei.Compiler;
#end

/*
 * haxei: interactive shell for haXe, based on hscript
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

class Shell extends Console {
	
	var stdin : Input;
	var stdout : Output;
	var stderr : Output;
	
	public function new( stdin : Input, stdout : Output, stderr : Output, ?set : Hash<Dynamic>, ?execute : Array<String> ) {
		
		this.stdin = stdin;
		this.stdout = stdout;
		this.stderr = stderr;
		
		super( set, execute );
	}
	
	override function init( ?set : Hash<Dynamic>, ?exec : Array<String> ) : Void {
		super.init( set );
		
		if ( null != exec )
			for ( exp in exec )
				execute( exp );
		
		while ( execute( read() ) ) { }
		
	}
	
	
	// ---- input & output
	
	function read() : String {
		print( prompt );
		var line = '';
		try {
			line = read_line();
		}
		catch ( e : Eof ) {
			quit();
		}
		if ( '..' == line.substr( 0, 2 ) ) {
			var b = new StringBuf();
			if ( line.length > 2 )
				b.add( line.substr( 2 ) );
			while ( try { print( continue_prompt ); line = read_line(); true; } catch ( e : Eof ) { false; } ) {
				if ( ';;' == line.substr( line.length - 2 ) ) {
					if ( 2 != line.length )
						b.add( line.substr( 0, line.length - 1 ) );
					break;
				}
				b.add( line );
			}
			return b.toString();
		}
		else {
			return line;
		}
	}
	
	function read_line() : String {
		return stdin.readLine();
	}
	
	override function print( msg : String ) : Void {
		stdout.writeString( msg );
	}
	
	override function println( msg : String ) : Void {
		stdout.writeString( msg  + '\n' );
	}
	
	override function error( msg : String ) : Void {
		stderr.writeString( 'ERROR ' + msg + CallStack.toString( CallStack.exceptionStack() ) + '\n' );
	}
	

	// ---- basic shell
	
	static function main() {
		#if ( neko || cpp )
		var stdin = Sys.stdin();
		var stdout = Sys.stdout();
		var stderr = Sys.stderr();
		new Shell(
			stdin,
			stdout,
			stderr, 
			{
				var h = new Hash<Dynamic>();
				h.set( 'Type', Type );
				h.set( 'Reflect', Reflect );
				h.set( 'Array', Array );
				h.set( 'EReg', EReg );
				h.set( 'Hash', Hash );
				h.set( 'IntHash', IntHash );
				h.set( 'Lambda', Lambda );
				h.set( 'List', List );
				h.set( 'Math', Math );
				h.set( 'Std', Std );
				h.set( 'String', String );
				h.set( 'StringBuf', StringBuf );
				h.set( 'StringTools', StringTools );
				h;
			},
			[
				'"haxei - haXe interactive"',
				'"Copyright (c) 2012 Jonas Malaco Filho"',
				'"Powered by haXe (haxe.org) and neko (nekovm.org)"',
				'""',
				'helpAll()',
				'""'
			]
		);
		#else
		throw 'Platform not supported';
		#end
	}
	
}