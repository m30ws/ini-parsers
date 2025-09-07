using System;
using System.Collections;
using System.IO;

class Program
{
	static string GetCwd()
	{
		var mainmodule = System.Diagnostics.Process.GetCurrentProcess().MainModule;
		string? dirname = Path.GetDirectoryName(mainmodule is not null ? mainmodule.FileName : ".");
		return dirname ?? ".";
	}

	static int Main(string[] args)
	{
		string input_filename = "input.ini";
		string output_filename = "output.ini";
		if (args.Length > 0)
		{
			input_filename = args[0];
		}
		// if (args.Length > 1)
		// {
		// 	output_filename = args[1];
		// }

		input_filename = Path.Combine(GetCwd(), input_filename);
		if (!File.Exists(input_filename))
		{
			Console.WriteLine($"Cannot open {input_filename} !");
			return -1;
		}
		Console.WriteLine($"\nOpened {input_filename}.\n");

		/* Or: */
	/*
		string ini_in_mem = """

			; jjjj  = kkk     
			[henlo]
			abc = def
			[[ttt]]
			ghi = jkl
			# 

		""";
		var tbl = INI.ParseString(ini_in_mem);
		INI.Print(tbl);

		INI.Set(tbl, "mnopqr", "@@@@", "----");
		INI.Print(tbl);
		Console.WriteLine();
		var section = INI.GetSection(tbl, "henlo") ?? new Hashtable();
		foreach (string key in section.Keys)
		{
			Console.WriteLine("Section [henlo] elem: '{0}' :: '{1}'", key, section[key]);
		}
	*/

		/* Or: */
	/*
		var inicontents = INI.Parse(input_filename);
		INI.Print(inicontents);
	*/

		/* Or: */
		var ini = new INI(input_filename);
		ini.Print();
		Console.WriteLine("\nSet()'ting new sections & keys...");
		ini.Set("novi krc", "markovo", "mudo666");
		ini.Set("[novikrc2.novi3]", "jos i drugo", "mudo");
		Console.WriteLine("\nDisplaying new struct:");
		ini.Print();
		if (args.Length > 1) {
			Console.WriteLine($"\nSaving new structure to file: {Path.Combine(GetCwd(), output_filename)}");
			ini.Save(Path.Combine(GetCwd(), output_filename));
		}

		Console.WriteLine("\nDone.");
		return 0;
	}
}
