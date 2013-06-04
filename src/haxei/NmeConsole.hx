package haxei;

#if nme
import haxe.Log;
import haxe.PosInfos;

import nme.display.FPS;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.Lib;
import nme.system.System;
import nme.text.TextField;
import nme.text.TextFieldType;
import nme.text.TextFormat;
import nme.ui.Keyboard;
import haxe.ds.StringMap in Hash;
#end

/*
 * Nme console
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

class NmeConsole extends Console {
#if nme

	// input
	var inBuffer : Array<String>;
	var inBufferMaxSize : Int;
	var inTextField : TextField;
	var pos : Int;
	
	// output
	var outBuffer : List<String>;
	var outBufferMaxSize : Int;
	var outTextField : TextField;
	
	var echo : Bool;
	
	public function new( inField : TextField, outField : TextField, ?set : Hash<Dynamic>, ?execute : Array<String> ) {
		inTextField = inField;
		outTextField = outField;
		super( set, execute );
		configureNme();
	}
	
	function configureNme() : Void {
		inTextField.addEventListener( MouseEvent.MOUSE_WHEEL, function( e : MouseEvent ) {
			inTextField.scrollV -= e.delta;
		} );
		inTextField.addEventListener( KeyboardEvent.KEY_DOWN, function( e : KeyboardEvent ) {
			if ( e.keyCode == Keyboard.UP && e.ctrlKey && !e.altKey && !e.shiftKey ) {
				if ( 0 <= --pos )
					inTextField.text = inBuffer[pos];
				else
					pos = -1;
			}
		} );
		inTextField.addEventListener( KeyboardEvent.KEY_DOWN, function( e : KeyboardEvent ) {
			if ( e.keyCode == Keyboard.DOWN && e.ctrlKey && !e.altKey && !e.shiftKey ) {
				if ( inBuffer.length > ++pos )
					inTextField.text = inBuffer[pos];
				else {
					pos = inBuffer.length;
					inTextField.text = '';
				}
			}
		} );
		inTextField.addEventListener( KeyboardEvent.KEY_DOWN, function( e : KeyboardEvent ) {
			if ( e.keyCode == Keyboard.ESCAPE && !e.ctrlKey && !e.altKey && !e.shiftKey ) {
				pos = inBuffer.length;
				inTextField.text = '';
			}
		} );
		
		outTextField.addEventListener( MouseEvent.MOUSE_WHEEL, function( e : MouseEvent ) {
			outTextField.scrollV -= e.delta;
		} );
	}
	
	override function init( ?set : Hash<Dynamic>, ?exec : Array<String> ) : Void {
		super.init( set );
		
		inBuffer = [];
		inBufferMaxSize = 300;
		pos = 0;
		
		outBuffer = new List();
		outBufferMaxSize = 1000;
		
		inputConfig();
		outputConfig();
		
		echo = false;
		if ( null != exec )
			for ( exp in exec )
				execute( exp );
		echo = true;
	}
	
	override function defaults() : Void {
		prompt = '> ';
		continue_prompt = '  ';
		multiline = true;
	}
	
	function inputConfig() : Void {
		inTextField.addEventListener( KeyboardEvent.KEY_DOWN, function ( e : KeyboardEvent ) {
			if ( e.keyCode == Keyboard.ENTER && e.ctrlKey && !e.altKey && !e.shiftKey ) {
				e.stopPropagation();
				var text = inTextField.text;
				inTextField.text = '';
				execute( text );
			}
		} );
	}
	
	override function execute( text : String ) : Bool {
		if ( StringTools.trim( text ) != '' ) {
			addToInBuffer( text );
			if ( echo )
				printEcho( text );
			return super.execute( text );
		}
		return true;
	}
	
	function outputConfig() : Void {
		
	}
	
	function addToOutBuffer( data : String ) : Void {
		outBuffer.add( data );
		while ( outBuffer.length > outBufferMaxSize )
			outBuffer.pop();
	}
	
	function addToInBuffer( data : String ) : Void {
		inBuffer.push( data );
		while ( inBuffer.length > inBufferMaxSize )
			inBuffer = inBuffer.slice( inBuffer.length - inBufferMaxSize );
		pos = inBuffer.length;
	}
	
	function printHtml( msg : String ) : Void {
		addToOutBuffer( msg );
		showOutput();
	}
	
	function printEcho( msg : String ) : Void {
		printHtml( prompt + '<b>' + msg.split( '\n' ).join( '\n</b>' + continue_prompt + '<b>' ) + '\n</b>' );
	}
	
	override function print( msg : String ) : Void {
		printHtml( htmlEscape( msg ) );
	}
	
	override function error( msg : String ) : Void {
		printHtml( '<b>ERROR </b>' + htmlEscape( msg + haxe.Stack.toString( haxe.Stack.exceptionStack() ) ) + '\n' );
	}
	
	function showOutput() : Void {
		outTextField.htmlText = outBuffer.join( '' );
		outTextField.scrollV = outTextField.numLines;
	}
	
	function htmlEscape( s : String ) { return StringTools.htmlEscape( s ); }
	
	override function quit() : Void {
		System.exit( 0 );
	}
	
	function setEcho( v : Bool ) : Void {
		echo = v;
	}
	
	override function set_custom_variables() : Void {
		super.set_custom_variables();
		interp.variables.set( 'echo', setEcho );
		set_help( 'echo', 'Echo user input on output?', [ 'value' ] );
	}
	
	public static function main() : Void {
		
		#if debug
		Lib.current.addChild( new FPS( Lib.current.stage.stageWidth - 100, 20, 0 ) );
		#end
		
		Lib.current.stage.addEventListener( KeyboardEvent.KEY_DOWN, function( e : KeyboardEvent ) {
			if ( e.keyCode == Keyboard.F4 && e.altKey && !e.ctrlKey && !e.shiftKey )
				System.exit( 0 );
		} );
		
		var textFormat = new TextFormat( '_typewriter', 12, 0 );
		
		var inp = new TextField();
		Lib.current.addChild( inp );
		inp.type = TextFieldType.INPUT;
		inp.defaultTextFormat = textFormat;
		inp.text = '';
		inp.width = inp.stage.stageWidth;
		inp.height = Math.round( inp.stage.stageHeight * .3 / inp.textHeight ) * inp.textHeight;
		inp.y = inp.stage.stageHeight - inp.height;
		inp.multiline = true;
		inp.wordWrap = true;
		inp.border = true;

		
		var out = new TextField();
		Lib.current.addChild( out );
		out.defaultTextFormat = textFormat;
		out.text = '';
		out.width = inp.width;
		out.height = inp.y;
		out.multiline = true;
		out.wordWrap = true;
		out.border = true;
		
		Lib.current.stage.focus = inp;
		
		var shell = new NmeConsole(
			inp,
			out,
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
		Log.trace = function( v, ?p:PosInfos ) { shell.println( p.fileName+':'+p.lineNumber+': '+v ); };
	}

#end
}