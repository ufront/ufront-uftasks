package cmd;

import massive.neko.io.File;
import massive.neko.io.FileSys;
import massive.haxe.log.Log;
import massive.neko.cmd.Command;
import neko.io.Process;

class ServerCommand extends Command
{
	private var model:File;
	
	public function new():Void
	{
		super();
		//addPreRequisite(PackageForHaxelibCommand);
	}
	
	override public function initialise():Void
	{
		
	}

	override public function execute():Void
	{
		// Start at the current directory, and go up until we find the project root
		var cwd = console.dir;
		while (cwd.resolveFile(".uftool").exists == false)
		{
			cwd = cwd.parent;
		}

		trace ("Project directory is : " + cwd.path.toString());

		trace ("Starting server at http://localhost:2000/");

		//TODO: pass on the same parameters as nekotools

		var p = new Process("nekotools", [
			"server",
			"-p", "2000",
			"-h", "localhost",
			"-d", cwd.path.toString() + "/bin",
			"-rewrite"
		]);

		//TODO: output the data from nekotools

		p.exitCode();
	}
	

}