package ufront.tasks;

import mcli.CommandLine;
import mcli.Dispatch;
import minject.Injector;
import sys.io.*;
import sys.FileSystem;
import ufront.log.FileLogger;
import ufront.log.Message;
import ufront.log.MessageList;
import ufront.api.UFApi;
import haxe.PosInfos;
using haxe.io.Path;
using StringTools;

class UFTaskSet extends CommandLine {

	/**
		The injector for this task set.

		Set during the constructor, and injection into this object is performed immediately.
	**/
	@:skip public var injector(default,null):Injector;

	/**
		The messages list.  This must be injected for `ufTrace`, `ufLog`, `ufWarn` and `ufError` to function correctly.

		You can call `useCLILogging()` to set up a message list appropriate for CLI usage.
	**/
	@:skip @inject public var messages:MessageList;

	/**
		Set up the TaskSet.

		This will perform dependency injection
	**/
	public function new( ?injector:Injector ) {
		super();
		this.injector = (injector!=null) ? injector : new Injector();
		this.injector.map( Injector ).toValue( this.injector );
	}

	/**
		Set up the logging to direct all traces, logs, warnings and error messages to the command line.

		Optionally you can also write to a logFile (the path should be specified relative to the content directory).
	**/
	@:skip
	public function useCLILogging( ?logFile:String ):UFTaskSet {
		var logFilePath = null;
		var file:FileOutput = null;
		if ( logFile!=null ) {
			var contentDir:String = injector.getInstance( String, "contentDirectory" );
			logFilePath = contentDir.addTrailingSlash()+logFile;
			var logFileDirectory = logFilePath.directory();
			if ( FileSystem.exists(logFileDirectory)==false )
				FileSystem.createDirectory( logFileDirectory );
			
			var line = '${Date.now()} [UFTask Runner] ${Sys.args()}';
			
			#if nodejs
				// hxnodejs has no FileInput implemention (yet)
				js.node.Fs.appendFileSync( logFilePath, '$line\n' );
			#else
				file = File.append( logFilePath );
				file.writeString( '$line\n' );
			#end
			
		}
		function onMessage( msg:Message ) {
			var line = FileLogger.format( msg );
			
			Sys.println( line );
#if nodejs
			// hxnodejs has no FileInput implemention (yet)
			if ( logFilePath!=null ) js.node.Fs.appendFileSync( logFilePath, '\t$line\n' );
#else
			if ( file!=null ) file.writeString( '\t$line\n' );
#end
		}
		haxe.Log.trace = function(msg:Dynamic,?pos:PosInfos) onMessage({ msg: msg, pos: pos, type:MTrace });
		injector.map( MessageList ).toValue( new MessageList(onMessage) );
		return this;
	}

	/**
		Execute the current task set, given a set of arguments passed in from the command line.

		Please note this will perform dependency injection on `this` before executing the request with the given args.

		Example usage:

		```haxe
		new Tasks().execute( Sys.args() );
		```
	**/
	@:skip
	public function execute( args:Array<String> ) {
		injector.injectInto( this );
		new mcli.Dispatch( args ).dispatch( this );
	}

	/**
		Execute a sub-task set, passing the remaining arguments through.

		The class will be created through dependency injection.

		Example usage:

		```haxe
		public function setup( d:Dispatch ) {
			executeSubTasks( d, SetupTasks );
		}
		```
	**/
	@:skip
	public function executeSubTasks( d:Dispatch, cls:Class<UFTaskSet> ) {
		d.dispatch( injector.instantiate(cls) );
	}

	/**
		Show this message.
	**/
	public function help()
	{
		Sys.println(this.showUsage());
	}

	/**
		A shortcut to `HttpContext.ufTrace`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufTrace( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:MTrace });

	/**
		A shortcut to `HttpContext.ufLog`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufLog( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:MLog });

	/**
		A shortcut to `HttpContext.ufWarn`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufWarn( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:MWarning });

	/**
		A shortcut to `HttpContext.ufError`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufError( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:MError });
}
