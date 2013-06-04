package uftool.cmd;

import massive.neko.io.File;
import massive.neko.io.FileSys;
import massive.haxe.log.Log;
import massive.neko.cmd.Command;
import ufront.tasks.AdminTaskSet;
using Lambda;
using ufront.util.TimeOfDayTools;

class RunTaskCommand extends Command
{
	public function new():Void
	{
		super();
	}
	
	override public function initialise():Void
	{
		
	}

	override public function execute():Void
	{
		// Find the correct task set, prompt the user as needed

		var taskSetInput = console.getNextArg();
		var taskSetMap = getTaskSetMap();
		var taskSet:AdminTaskSet = null;
		if (taskSetInput != null)
		{
			// Try find the task set.  Search for exact match first, then lowercase, then just the final section
			taskSet = taskSetMap.filter(function (ts) return ts.taskSetName == taskSetInput).first();
			if (taskSet == null) taskSet = taskSetMap.filter(function (ts) return ts.taskSetName.toLowerCase() == taskSetInput.toLowerCase()).first();
			if (taskSet == null) taskSet = taskSetMap.filter(function (ts) return ts.taskSetName.split(".").pop().toLowerCase() == taskSetInput.toLowerCase()).first();
			
			if (taskSet == null) Sys.println('\nTaskSet "$taskSetInput" was not found.'); 
		}
		if (taskSet == null)
		{
			Sys.println('\nAvailable TaskSets');
			taskSet = pickOption(taskSetMap);
		}
		Sys.println('\nUsing TaskSet ${taskSet.taskSetTitle}');
		
		// Find the correct task in that task set, prompt user as necessary.

		var taskName = console.getNextArg();
		if (taskName != null)
		{
			// Check that it exists.  If it doesn't, set to null so they can pick one.
			var matchingTask = taskSet.tasks.filter(function (t) return t.name.toLowerCase() == taskName.toLowerCase())[0];
			if (matchingTask == null)
			{
				Sys.println('\nTask "$taskName" in TaskSet "$taskSetInput" was not found.'); 
				taskName = null;
			}
			else 
			{
				taskName = matchingTask.name;
			}
		}
		if (taskName == null)
		{
			var taskMap = new Map<String, String>();
			for (t in taskSet.tasks)
			{
				taskMap.set(t.title, t.name);
			}
			Sys.println('\nAvailable Tasks:');
			taskName = pickOption(taskMap);
		}
		Sys.println('Attempt to execute task $taskName');

		// Get all required variables

		for (inputName in taskSet.taskSetInputs)
		{
			var input = console.getOption(inputName, inputName);
			Reflect.setProperty(taskSet, inputName, input);
		}
		var taskInputs = [];
		for (inputName in taskSet.getTaskInputs(taskName))
		{
			var input = console.getOption(inputName, inputName);
			taskInputs.push(input);
		}
		
		// Execute the task
		var startTime = Sys.time();
		var result = taskSet.run(taskName, taskInputs, true);
		var timeTaken = Std.int(Sys.time() - startTime);

		trace ('Time taken: $timeTaken seconds');
	}

	private function getTaskSetMap()
	{
		var m = new Map<String, AdminTaskSet>();
		for (ts in AdminTaskSet.allTaskSets)
		{
			m.set(ts.taskSetTitle, ts);
		}
		return m;
	}
	
	private function selectTaskName(set:Class<Dynamic>)
	{
		return console.prompt("Please choose a taskName:");
	}

	private function pickOption<T>(?optionMap:Map<String,T>, ?options:Iterable<T>, ?prompt:String)
	{
		if (prompt == null) prompt = "Please select an option";

		// If we're using just an iterable of options, set it up as a hash in the same format as optionMap
		if (options != null && optionMap == null)
		{
			optionMap = new Map();
			for (o in optionMap)
			{
				optionMap.set(Std.string(o), o);
			}
		}

		// Display choices, receive input, loop until a valid choice is selected.
		var ret:T = null;
		while (ret == null)
		{
			var i = 0;
			var choices:Array<T> = [];
			for (key in optionMap.keys())
			{
				i++;
				choices[i] = optionMap.get(key);
				Sys.println('  $i: $key');
			}

			var selection = Std.parseInt(console.prompt('\n$prompt:'));

			// Set to the choice.  If it's not found, it's null, and will loop again.
			if (selection != null) ret = choices[selection];
		}

		return ret;
	}
}