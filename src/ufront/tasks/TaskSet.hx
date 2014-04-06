package ufront.tasks;

import haxe.web.Dispatch;
import Sys.println;
import Sys.print;
import haxe.macro.Expr;
using Type;
using StringTools;
using Reflect;

@:rtti
@:deprecated
class TaskSet {

	public function new() {}

	public function doDefault( ?d:Dispatch ) {
		doHelp();
	}

	@help("Use `help` on any TaskSet to get the information and usage for available tasks.")
	public function doHelp( ?d:Dispatch ) {
		if ( d!=null )
			println( 'Unknown command: ${d.parts.join(" ")}' );

		println( 'Ufront Command Line Task Runner' );
		var className = this.getClass().getClassName();
		println( '$className Usage:' );

		var cl = this.getClass();
		var usageInfo = getUsageInfoFromClass( cl );
		var meta = haxe.rtti.Meta.getFields(cl);
		
		for ( f in cl.getInstanceFields() ) {
			if ( f.startsWith("do") ) {
				var name = f.charAt(2).toLowerCase() + f.substr(3);
				if ( name!="default" ) {
					var usage = usageInfo.exists(name) ? usageInfo.get(name) : "";
					var help = 
						if ( name=="help" )
							"Use `help` on any TaskSet to get the usage information for available tasks."
						else 
							try meta.field(f).help.shift() catch (e:Dynamic) "";

					var line = '  $name $usage';
					if ( help!="" ) line = line.rpad(" ",35) + '     // $help';
					println( line );
				}
			}
		}
	}

	function getUsageInfoFromClass( cl:Class<Dynamic> ):Map<String,String> {
		var fieldUsage = new Map();
		var x = Xml.parse(untyped cl.__rtti).firstElement();
		var infos = new haxe.rtti.XmlParser().processElement(x);
		switch (infos) {
			case TClassdecl(c):
				for (f in c.fields) {
					if (f.name.startsWith("do")) {
						switch (f.type) {
							case CFunction(args,_):
								var usageArgs = [];
								for (arg in args) {
									switch (arg.t) {
										case CClass("ufront.web.Dispatch",_), CClass("haxe.web.Dispatch",_):
											usageArgs.push( '[taskset]' );
										case CClass(n,_), CAbstract(n,_), CTypedef(n,_), CEnum(n,_):
											var usage = '${arg.name}:$n' ;
											if ( arg.opt ) usage = '[?$usage]';
											usageArgs.push( usage );
										case CAnonymous(fields):
											for ( param in fields ) {

												var optional = arg.opt;
												var type = param.type;
												switch (type) {
													case CTypedef("Null", list): 
														type = list.first();
														optional = true;
													case _:
												}

												switch (type) {
													case CClass(n,_), CAbstract(n,_), CTypedef(n,_), CEnum(n,_):
														var usage = '-${param.name}:$n';
														if ( optional ) usage = '[?$usage]';
														usageArgs.push( usage );
													case _:
												}
											}
										case _:
									}
								}
								var usage = usageArgs.join(" ");
								var name = f.name.charAt(2).toLowerCase() + f.name.substr(3);
								fieldUsage[name] = usage;
							case _:
						}
					}
				}
			case _:
		}
		return fieldUsage;
	}

	@:access(haxe.web.Dispatch)
	public static macro function run( api:ExprOf<TaskSet>, args:ExprOf<Array<String>> ) {
		
		var dispatchConf = Dispatch.makeConfig( api );
		
		return macro {
			var request = TaskSet.processArgs( $args );
			var fakeUrl = request.parts.join("/");
			var params = request.params;
			var cfg = $dispatchConf;
			var d = new haxe.web.Dispatch(fakeUrl,params);
			try {
				d.runtimeDispatch(cfg);
			} 
			catch (e:DispatchError) {
				switch (e) {
					case DENotFound( part ):
						Sys.println( 'ERROR: '+part+' not found' );
					case DEInvalidValue:
						Sys.println( 'ERROR: Invalid value supplied' );
					case DEMissing:
						Sys.println( 'ERROR: A required argument is missing...' );
					case DEMissingParam( p ):
						Sys.println( 'ERROR: A required parameter is missing ('+p+')' );
					case DETooManyValues:
						Sys.println( 'ERROR: Too many arguments supplied' );
				}
				// if ( d.controller!= null && Std.is(d.controller,TaskSet) )
				//     cast (d.controller, TaskSet).doHelp();
				// else $api.doHelp();
				$api.doHelp();
			}
		};
	}

	public static function processArgs( args:Array<String> ) {
		var parts:Array<String> = [];
		var params:Map<String,String> = new Map();
		while ( args.length > 0 ) {
			var p = args.shift();
			if ( p.charAt(0) == "-" && p.length > 1 ) {
				var value = (args.length>0) ? args.shift() : "";
				params.set( p.substr(1), value );
			}
			else parts.push( p );
		}
		return {
			parts: parts,
			params: params
		}
	}
}