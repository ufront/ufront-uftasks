package haxei;

import hscript.Interp;
import hscript.Expr;
import haxe.ds.StringMap in Hash;

/*
 * Adapted interpreter from hscript
 * Preserves state
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


class Interpreter extends Interp {

	var preserve : Bool;
	
	public function new( ?preserve = false ) {
		this.preserve = preserve;
		super();
		reset_locals();
		reset_globals();
	}
	
	override public function execute( expr : Expr ) : Dynamic {
		if ( !preserve )
			reset_locals();
		return exprReturn(expr);
	}
	
	public function reset_locals() : Void {
		locals = new Hash();
	}
	
	public function reset_globals() : Void {
		variables = new Hash();
		variables.set("null",null);
		variables.set("true",true);
		variables.set("false",false);
		variables.set("trace",function(e) haxe.Log.trace(Std.string(e),cast { fileName : "hscript", lineNumber : 0 }));
	}
	
	public function get_locals_names() {
		return locals.keys();
	}
	
	public function get_local( name : String ) {
		return locals.get( name ).r;
	}
	
	public function get_globals_names() {
		return variables.keys();
	}
	
	public function get_global( name : String ) {
		return variables.get( name );
	}
	
}