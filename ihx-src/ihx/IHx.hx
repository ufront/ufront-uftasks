/*
  Copyright (c) 2009-2013, Ian Martins (ianxm@jhu.edu)

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
*/

package ihx;

import sys.io.FileInput;
import neko.Lib;
import sys.FileSystem;
import ihx.CmdProcessor;
using StringTools;

/**
   IHx is an interactive session for haxe programming.  The code is basically a command line
   interface for Hscript.
**/
class IHx
{
    private static var VERSION = "0.2.2";

    /** the source for commands **/
    private var console :ConsoleReader;

    /**
       start the interpreter
    **/
    public static function main()
    {
        var interpreter = new IHx();
        interpreter.run();
    }

    /**
       populate the builtin variable lists, instantiate the hscript engine
    **/
    public function new()
    {
        console = new ConsoleReader();
    }
  
    /**
       get commands from the console, process them, display output
       handle ihx commands, get haxe statement (can be multiline), parse it, pass to execution method
    **/
    public function run()
    {
        var processor = new CmdProcessor();

        for ( arg in Sys.args() )
        {
            if ( arg.startsWith("-lib=") )
            {
                var lib = arg.substr(5);
                processor.process( 'addlib $lib' );
            }
            else if ( arg.startsWith("-cp=") )
            {
                var cp = arg.substr(4);
                processor.process( 'addpath $cp' );
            }
            else if ( arg.startsWith("-import=") )
            {
                var imp = arg.substr(8);
                processor.process( 'import $imp;' );
            }
            else if ( FileSystem.exists(arg) )
            {
                Sys.setCwd(arg);
            }
            else 
            {
                Lib.println('Unknown argument: $arg');
                Lib.println("usage: neko ihx [workingdir] [-lib=myhaxelib] [-cp=/some/class/path/] [-import=haxe.ds.*]");
                Sys.exit(1);
            }
        }

        Lib.println("haxe interactive shell v" + VERSION);
        Lib.println("type \"help\" for help");


        while( true )
        {
            // initial prompt
            console.cmd.prompt = ">> ";
            Lib.print(">> ");

            while (true)
            {
                try
                {
                    var ret = processor.process(console.readLine());
                    if( ret != null )
                        Lib.println(ret+"\n");
                }
                catch (ex:CmdError)
                {
                    switch (ex)
                    {
                    case IncompleteStatement:
                        {
                            console.cmd.prompt = ".. "; // continue prompt
                            Lib.print(".. ");
                            continue;
                        }
                    case InvalidStatement(msg): Lib.println(msg);
                    }
                }

                // restart after an error or completed command
                console.cmd.prompt = ">> ";
                Lib.print(">> ");
            }
        }
    }
}
