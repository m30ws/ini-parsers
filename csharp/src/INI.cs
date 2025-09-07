using System;
using System.Collections;
using System.IO;
using System.Linq;
using System.Text;

class INI
{
	public enum IniParserAction
	{
		PARSE_BREAK,
		PARSE_CONTINUE,
	}

	protected Hashtable? _inicontents = null;

	public INI()
	{
		this._inicontents = null;
	}

	public INI(StreamReader reader)
	{
		this._inicontents = Parse(reader);
	}

	public INI(string filename)
	{
		this._inicontents = Parse(filename);
	}

	public static Hashtable Parse(StreamReader reader)
	{
		Hashtable inicontents = new Hashtable();
		string? current_section_name = null;
		uint line_no = 0;
		for (; ; )
		{
			string? line = reader.ReadLine();
			if (line is null)
			{
				break;
			}
			if (ParseLine(inicontents, line, ref current_section_name) == IniParserAction.PARSE_BREAK)
			{
				Console.Error.WriteLine("\nInvalid line provided (at line: {0})\n", line_no + 1);
				break;
			}
			line_no++;
		}
		return inicontents;
	}

	public static Hashtable Parse(string filename)
	{
		using (StreamReader sr = File.OpenText(filename))
		{
			return Parse(sr);
		}
	}

	public static Hashtable ParseString(string raw)
	{
		return Parse(ReaderFromString(raw));
	}

	public static StreamReader ReaderFromString(string raw)
	{
		return new StreamReader(
			new MemoryStream(
				System.Text.Encoding.UTF8.GetBytes(
					raw.ToCharArray()
				)
			)
		);
	}

	public static IniParserAction ParseLine(Hashtable inicontents, string? line, ref string? current_section_name)
	{
		if (inicontents == null || line == null) return IniParserAction.PARSE_BREAK;
		if (line.Length == 0) return IniParserAction.PARSE_CONTINUE;

		line = line.TrimStart();

		if (line[0] == ';' || line[0] == '#')
		{
			return IniParserAction.PARSE_CONTINUE;
		}

		// Check if this is a section definition
		if (line[0] == '[' && line[line.Length - 1] == ']')
		{
			string sect_name = line.Substring(1, line.Length - 1 - 1);
			inicontents.Add(sect_name, new Hashtable());

			current_section_name = sect_name;
			return IniParserAction.PARSE_CONTINUE;
		}

		// If section name is not set previously, it makes no sense to even parse keyvals
		if (current_section_name == null)
		{
			Console.Error.WriteLine("Property encountered before any section declaration");
			return IniParserAction.PARSE_BREAK;
		}

		// Split key and value
		int sep_idx = line.IndexOf("=");
		if (sep_idx == -1)
		{
			Console.Error.WriteLine("Invalid keyval pair (no '=' in line)");
			return IniParserAction.PARSE_BREAK;
		}
		string key = line[..sep_idx];
		string value = line[(sep_idx + 1)..];

		key = key.Trim(); // remove all leading and trailing whitespaces for key
		value = value.TrimEnd(); // remove all trailing whitespaces for value
		if (value.Length > 0 && char.IsWhiteSpace(value.First()))
			value = value.Remove(0, 1); // remove (only) first whitespace char

		if (key.Length == 0)
		{
			// Encountered invalid empty key for value, but continue
			return IniParserAction.PARSE_CONTINUE;
		}

		// Hard veri hard error sudnt hepn :(
		if (current_section_name == null)
		{
			Console.Error.WriteLine("Invalid state; tried to assign value to key but current section isn't set");
			return IniParserAction.PARSE_BREAK;
		}

		Hashtable section = (Hashtable)inicontents[current_section_name]!;
		if (!section.Contains(key))
		{
			section.Add(key, value);
		}
		else
		{
			section[key] = value;
		}

		return IniParserAction.PARSE_CONTINUE;
	}

	public static void Print(Hashtable? inicontents)
	{
		Console.WriteLine("\nPrinting INI structure:");
		if (inicontents == null)
		{
			Console.WriteLine("  (Empty)");
			return;
		}
		foreach (string section in inicontents.Keys)
		{
			Hashtable? props = (Hashtable?)inicontents[section];
			if (props == null)
			{
				Console.WriteLine("  - {0} (0 props)", section);
				continue;
			}

			Console.WriteLine("  - {0} ({1} props)", section, props.Count);
			foreach (string prop in props.Keys)
			{
				Console.WriteLine("    - |{0}| :: |{1}|", prop, props[prop] ?? "<none>");
			}
		}
	}

	public static void Set(Hashtable? inicontents, string section_name, string key, object? value)
	{
		if (inicontents == null)
			return;

		Hashtable? section = (Hashtable?)inicontents[section_name];
		if (section == null)
		{
			// create the new section
			section = new Hashtable();
			inicontents.Add(section_name, section);
		}

		section[key] = value;
	}

	public static object? Get(Hashtable? inicontents, string section_name, string key)
	{
		if (inicontents == null)
			return null;

		Hashtable? section = (Hashtable?)inicontents[section_name];
		if (section == null)
			return null; // No given section

		return section[key];
	}

	public static Hashtable? GetSection(Hashtable? inicontents, string section_name)
	{
		if (inicontents == null || section_name == null)
			return null;

		return (Hashtable?)inicontents[section_name];
	}

	public static bool Save(Hashtable? inicontents, string filename)
	{
		if (inicontents == null || filename == null)
			return false;

		using (StreamWriter wr = new StreamWriter(File.OpenWrite(filename)))
		{
			foreach (string section_name in inicontents.Keys)
			{
				// print sect name always
				wr.WriteLine("[{0}]", section_name);

				Hashtable? props = (Hashtable?)inicontents[section_name];
				if (props == null)
				{
					continue;
				}

				// Console.WriteLine("  - {0} ({1} props)", section, props.Count);
				foreach (string key in props.Keys)
				{
					wr.WriteLine("{0} = {1}", key, props[key]);
					// Console.WriteLine("    - |{0}| :: |{1}|", key, props[key] ?? "<none>");
				}

				wr.WriteLine();

			}
		}
		return true;
	}
		
	// Methods if used as an instance

	public void Print()
	{
		Print(this._inicontents);
	}

	public void Set(string section_name, string key, object? value)
	{
		Set(this._inicontents, section_name, key, value);
	}

	public object? Get(string section_name, string key)
	{
		return Get(this._inicontents, section_name, key);
	}

	public Hashtable? GetSection(string section_name)
	{
		return GetSection(this._inicontents, section_name);
	}

	public bool Save(string filename)
	{
		return Save(this._inicontents, filename);
	}
}
