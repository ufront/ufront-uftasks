package haxei;

import hscript.Expr;
import hscript.Parser;
import haxe.ds.StringMap in Hash;

/*
 * Basics for haxei shells
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

class Console {
	
	var prompt : String;
	var continue_prompt : String;
	var multiline : Bool;
	
	var interp : Interpreter;
	var parser : Parser;
	var auto_types : Hash<Dynamic>;
	var auto_listing : Array<String>;
	
	var help : Hash<String>;

	
	// ---- construction
	
	function new( ?set : Hash<Dynamic>, ?execute : Array<String> ) {
		prepare();
		init( set, execute );
	}
	
	function defaults() : Void {
		prompt = 'haxei> ';
		continue_prompt = '.. ';
		multiline = false;
	}
	
	function prepare() : Void {
		
		defaults();
		
		interp = new Interpreter( true );
		parser = new Parser();
		
		auto_register();
		
		help = new Hash();

		reset_globals();
		
	}
	
	function init( ?set : Hash<Dynamic>, ?execute : Array<String> ) : Void {
		if ( null != set )
			for ( k in set.keys() )
				interp.variables.set( k, set.get( k ) );
	}
	
	
	// ---- input/output/error helpers
	
	function print( msg : String ) : Void {
		trace( msg );
	}
	
	function println( msg : String ) : Void {
		print( msg + '\n' );
	}
	
	function error( msg : String ) : Void {
		println( 'ERROR ' + msg + haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );
	}
	
	
	// ---- expression evaluation
	
	function execute( s : String ) : Bool {
		if ( '' == StringTools.trim( s ) )
			return true;
		try {
			println( Std.string( interp.execute( parser.parseString( s ) ) ) );
		}
		catch ( e : Error ) {
			switch ( e ) {
				case EInvalidChar( c ) : error( 'invalid char \'' + String.fromCharCode( c ) + '\'(' + c + ')' );
				case EUnexpected( s ) : error( 'unexpected \'' + s + '\'' );
				case EUnterminatedString : error( 'unterminated string' );
				case EUnterminatedComment : error( 'unterminated comment' );
				case EUnknownVariable( v ) : error( 'unknown variable ' + v );
				case EInvalidIterator( v ) : error( 'invalid iterator ' + v );
				case EInvalidOp( op ) : error( 'invalid operator ' + op );
				case EInvalidAccess( f ) : error( 'invalid access ' + f );
			}
		}
		catch ( e : String ) {
			if ( 'quit' == e )
				return false;
			error( e );
		}
		catch ( e : Dynamic ) {
			error( e );
		}
		return true;
	}

	
	// ---- more builtin variables & functions
	
	function get_help( key : String ) : String {
		var msg = help.get( key );
		return null != msg ? msg : '';
	}
	
	function set_help( key : String, msg : String, ?parameters : Array<String> ) : Void {
		var val =  null == parameters ? key + ': ' + msg : key + '(' + parameters.join( ', ' ) + '): ' + msg;
		help.set( key, val );
	}
	
	function quit() : Void {
		throw 'quit';
	}
	
	function reset_locals() : Void {
		interp.reset_locals();
	}
	
	function help_all() : String {
		var keys = Lambda.array( { iterator : help.keys } );
		keys.sort( Reflect.compare );
		var x = [ 'Available help:' ];
		for ( k in keys )
			x.push( get_help( k ) );
		return x.join( '\n' );
	}
	
	function reset_globals() : Void {
		interp.reset_globals();
		for ( k in auto_types.keys() )
			interp.variables.set( k, auto_types.get( k ) );
		set_custom_variables();
	}
	
	function locals() {
		return Lambda.list( { iterator : interp.get_locals_names } );
	}
	
	function globals() {
		return Lambda.list( { iterator : interp.get_globals_names } );
	}
	
	
	// ---- other helpers
	
	function set_custom_variables() : Void {
		
		interp.variables.set( 'print', print );
		set_help( 'print', 'Print', [ 'value' ] );
		
		interp.variables.set( 'println', println );
		set_help( 'println', 'Print + newline', [ 'value' ] );
		
		interp.variables.set( 'enumParameters', Type.enumParameters );
		set_help( 'enumParameters', 'Return an array with the current enum parameters', [ 'enum' ] );
		
		interp.variables.set( 'exit', quit );
		set_help( 'exit', 'Exit', [] );
		
		interp.variables.set( 'help', get_help );
		set_help( 'help', 'Display help info for a variable', [ 'name:String' ] );
		
		interp.variables.set( 'helpAll', help_all );
		set_help( 'helpAll', 'Return all the help', [] );
		
		interp.variables.set( 'autoTypes', Lambda.list.bind( auto_listing ) );
		set_help( 'autoTypes', 'Return the list of all types registred at compilation', [] );
		
		interp.variables.set( 'quit', quit );
		set_help( 'quit', 'Exit', [] );
		
		interp.variables.set( 'resetGlobals', reset_globals );
		set_help( 'resetGlobals', 'Reset all global variables on the interpreter', [] );
		
		interp.variables.set( 'resetLocals', reset_locals );
		set_help( 'resetLocals', 'Reset all local variables on the interpreter', [] );
		
		interp.variables.set( 'locals', locals );
		set_help( 'locals', 'List local variables names', [] );
		
		interp.variables.set( 'globals', globals );
		set_help( 'globals', 'List globals variables names', [] );
		
	}
	
	
	// ---- macros
	
	macro static function auto_register() : haxe.macro.Expr {
		var pos = haxe.macro.Context.currentPos();
		var block = [ haxe.macro.Context.parse( 'auto_types = new Hash()', pos ), haxe.macro.Context.parse( 'auto_listing = new Array()', pos ) ];
		for ( type in Compiler.registred ) {
			var name = '';
			var resolve = '';
			switch ( type ) {
				case TEnum( n ) : name = n; resolve = 'resolveEnum';
				case TClass( n ) : name = n; resolve = 'resolveClass';
				case TType( n ) : name = n; resolve = 'resolveClass';
			}
			#if HAXEI_DEBUG
			trace( type );
			block.push( haxe.macro.Context.parse( 'trace( "Adding ' + name + '" )', pos ) );
			#end
			var parts = name.split( '.' );
			if ( 1 == parts.length ) {
				//trace( 'auto_types.set( "' + name + '", Type.resolveClass( "' + name + '" ) )' );
				block.push( haxe.macro.Context.parse( 'auto_types.set( "' + name + '", Type.' + resolve + '( "' + name + '" ) )', pos ) );
			}
			else {
				var preffix = [ 'auto_types.get( "' + parts[0] + '" )' ];
				//trace( 'if ( !' + preffix[0] + ' ) auto_types.set( "' + parts[0] + '", cast { } )' );
				block.push( haxe.macro.Context.parse( 'if ( !' + preffix[0] + ' ) auto_types.set( "' + parts[0] + '", cast { } )', pos ) );
				for ( i in 1...parts.length - 1 ) {
					var pre = preffix.join( '.' );
					//trace( 'if ( !Reflect.hasField( ' + pre + ', "' + parts[i] + '" ) ) ' + pre + '.' + parts[i] + ' = cast { }' );
					block.push( haxe.macro.Context.parse( 'if ( !Reflect.hasField( ' + pre + ', "' + parts[i] + '" ) ) ' + pre + '.' + parts[i] + ' = cast { }', pos ) );
					preffix.push( parts[i] );
				}
				preffix.push( parts[parts.length - 1] );
				//trace( preffix.join( '.' ) + ' = Type.resolveClass( "' + name + '" )' );
				block.push( haxe.macro.Context.parse( preffix.join( '.' ) + ' = Type.' + resolve + '( "' + name + '" )', pos ) );
			}
			block.push( haxe.macro.Context.parse( 'auto_listing.push( "' + name + '" )', pos ) );
		}
		block.push( haxe.macro.Context.parse( 'auto_listing.sort( Reflect.compare )', pos ) );
		return { expr : haxe.macro.Expr.ExprDef.EBlock( block ), pos : pos };
	}
	
}