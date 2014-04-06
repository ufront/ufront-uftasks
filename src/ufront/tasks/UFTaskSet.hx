package ufront.tasks;

import mcli.CommandLine;
import minject.Injector;
import sys.io.*;
import ufront.auth.YesBossAuthHandler;
import ufront.log.FileLogger;
import ufront.log.Message;
import ufront.api.UFApi;
import ufront.auth.UFAuthHandler;
import ufront.auth.UFAuthUser;
import haxe.PosInfos;
using haxe.io.Path;

class UFTaskSet extends CommandLine {

	/**
		Create an injector suitable for running UFTaskSet tasks from the Command Line Interface (CLI).

		@param contentDir The path, relative to the script directory, where the "contentDirectory" is located.  `uf-content` by default.
		@param logFile The path, relative to `contentDir`, of a file to write logs to.  Null by default.  If null, logs will not be written to files.
		@param apis A set of UFApi classes to be added to the injector.  If null, no classes will be added.
		@param auth An auth-handler to use in the APIs.  If null, a `YesBossAuthHandler` will be used, meaning all permissions are granted.
		@return An `minject.Injector` ready to use in your UFTaskSet.
	**/
	public static function buildCLIInjector( ?contentDir="uf-content", ?logFile:String, ?apis:Iterable<Class<UFApi>>, ?auth:UFAuthHandler<UFAuthUser> ) {
		
		var injector = new Injector();
		if ( auth==null ) auth = new YesBossAuthHandler();

		// Set up the tracing / file logging
		var file:FileOutput = null;
		if ( contentDir!=null && logFile!=null ) {
			var logFilePath = contentDir.addTrailingSlash()+logFile;
			file = File.append( logFilePath );
			var line = '${Date.now()} [UFTask Runner] ${Sys.args()}';
			file.writeString( '$line\n' );
		}
		function onMessage( msg:Message ) {
			var line = FileLogger.format( msg );
			Sys.println( line );
			if ( file!=null ) {
				file.writeString( '\t$line\n' );
			}
		}
		haxe.Log.trace = function(msg:Dynamic,?pos:PosInfos) onMessage({ msg: msg, pos: pos, type:Trace });
		var messageList = new MessageList(onMessage);

		// Map the default values
		injector.mapValue( String, contentDir, "contentDirectory" );
		injector.mapValue( MessageList, messageList );
		injector.mapValue( UFAuthHandler, auth );

		if ( apis!=null ) for ( api in apis ) {
			injector.mapClass( api, api );
		}

		return injector;
	}

	/**
		The injector for this task set.

		Set during the constructor, and injection into this object is performed immediately.
	**/
	var injector(default,null):Injector;
	
	/**
		The messages list.  This must be injected for `ufTrace`, `ufLog`, `ufWarn` and `ufError` to function correctly.

		When called from a web context, this will usually result in the HttpContext's `messages` array being pushed to.
	**/
	@inject var messages:MessageList;

	/**
		Set up the TaskSet.

		This will perform dependency injection
	**/
	public function new( injector:Injector ) {
		super();

		// Possible issues: MCLI requires public member variables to be dispatchers, but what if we want to inject, they need to be public too?
		// Workaround for now...
		this.injector = injector;
		this.messages = injector.getInstance( MessageList );

		injector.injectInto( this );
	}

	/**
		A shortcut to `HttpContext.ufTrace`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufTrace( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Trace });

	/**
		A shortcut to `HttpContext.ufLog`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufLog( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Log });

	/**
		A shortcut to `HttpContext.ufWarn`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufWarn( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Warning });

	/**
		A shortcut to `HttpContext.ufError`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufError( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Error });
}