package iniparser

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"

Ini :: distinct map[string](map[string]string)
IniError :: enum {
	Ok = 0,
	IO_Error,
	Invalid_Line,
	Invalid_Section,
	No_Active_Section,
	Allocator_Error,
	Invalid_Parameter
}
ini_error_to_string :: proc(err: IniError) -> string {
	switch err {
		case IniError.Ok:
			return "Ok"
		case IniError.IO_Error:
			return "IO Error"
		case IniError.Invalid_Line:
			return "Invalid Line"
		case IniError.Invalid_Section:
			return "Invalid Section"
		case IniError.No_Active_Section:
			return "No Active Section"
		case IniError.Allocator_Error:
			return "Allocator Error"
		case IniError.Invalid_Parameter:
			return "Invalid Parameter"
	}
	return ""
}

parse_ini_stream :: proc(stream: io.Stream) -> (Ini, IniError) {
	ini := make(Ini)
	current_section: string
	reader: bufio.Reader
	bufio.reader_init(&reader, stream)

	err_reader: io.Error = io.Error.None
	line: string
	for err_reader == io.Error.None {
		line, err_reader = bufio.reader_read_string(&reader, '\n')

		err_line := process_ini_line(line, &ini, &current_section)
		if err_line != IniError.Ok {
			delete(ini)
			return nil, err_line
		}
	}

	if err_reader != io.Error.EOF {
		delete(ini)
		return nil, IniError.IO_Error
	}
	return ini, IniError.Ok
}

process_ini_line :: proc(line: string, ini: ^Ini, current_section: ^string) -> (IniError) {
	if ini == nil do return IniError.Invalid_Parameter
	trimmed := strings.trim_space(line)
	if (len(trimmed) < 1) {
		// This is an empty line
		return IniError.Ok
	}
	if strings.starts_with(trimmed, ";") || strings.starts_with(trimmed, "#") {
		// This is a comment line
		return IniError.Ok
	}
	if strings.starts_with(trimmed, "[") || strings.ends_with(trimmed, "]") {
		// This is a new section
		sub, err := strings.substring(trimmed, 1, len(trimmed) - 1)
		if !err {
			return IniError.Invalid_Section
		}
		// ...create it
		err_sect := ini_ensure_section(ini, sub)
		if err_sect != IniError.Ok {
			return IniError.Allocator_Error // Invalid_Parameter would've been caught already
		}
		current_section^ = sub // store it
		return IniError.Ok
	}
	if len(ini) < 1 {
		// We need to encounter a [section] first
		return IniError.No_Active_Section
	}
	// This is the assignment
	spl, err := strings.split_n(trimmed, "=", 2)
	if err != nil {
		return IniError.Allocator_Error
	}
	// ...finally append the new elem
	keytrim := strings.trim_space(spl[0])
	valtrim := strings.trim_left_space(spl[1])
	if len(keytrim) > 0 {
		// Do not store empty keys (empty values are ok)
		(&ini[current_section^])[keytrim] = valtrim
	}
	return IniError.Ok
}

ini_destroy :: proc(ini: ^Ini) -> IniError {
	if ini == nil do return IniError.Invalid_Parameter
	for section_name, &section_data in ini {
		delete(section_data)
	}
	delete(ini^)
	return IniError.Ok
}

ini_get :: proc(ini: ^Ini, section: string, key: string) -> string {
	ref := ini_get_ref(ini, section, key)
	return ref^ if ref != nil else string{}
}

ini_get_or_default :: proc(ini: ^Ini, section: string, key: string, default: string) -> string {
	def := default
	return ini_get_or_default_ref(ini, section, key, &def)^
}

ini_get_ref :: proc(ini: ^Ini, section: string, key: string) -> ^string {
	return ini_get_or_default_ref(ini, section, key, nil)
}

ini_get_or_default_ref :: proc(ini: ^Ini, section: string, key: string, default: ^string) -> ^string {
	if ini == nil do return default
	if &ini[section] == nil do return default
	val := &ini[section][key]
	if val != nil do return val
	return default
}

ini_set :: proc(ini: ^Ini, section: string, key: string, value: string) -> IniError {
	if ini == nil do return IniError.Invalid_Parameter
	sect := &ini[section]
	if sect == nil {
		err_ensure := ini_ensure_section(ini, section)
		if err_ensure != IniError.Ok do return err_ensure
		sect = &ini[section]
	}
	sect[key] = value	
	return IniError.Ok
}

ini_ensure_section :: proc(ini: ^Ini, section: string) -> IniError {
	if ini == nil do return IniError.Invalid_Parameter
	if &ini[section] != nil do return IniError.Ok // Already exists
	ini[section] = make( map[string]string )
	if &ini[section] == nil do return IniError.Allocator_Error
	return IniError.Ok
}

ini_print :: proc(ini: ^Ini) {
	if ini == nil do return
	fmt.printf("<.INI structure>\n")
	for section_name, &section_data in ini {
		fmt.printf("  |\n  +-> [SECTION] \"%s\"\n", section_name)
		for key, &val in section_data {
			fmt.printf("  |     |\n")			
			fmt.printf("  |     +-> [PROP] \"%s\": \"%s\"\n", key, val)
		}
	}
	fmt.printf("  V\n")
}

ini_save :: proc(ini: ^Ini, filename: string) -> IniError {
	if ini == nil do return IniError.Invalid_Parameter

	fp, err_open := os.open(filename, os.O_WRONLY | os.O_CREATE)
	if err_open != os.ERROR_NONE {
		fmt.printf("%s\n", err_open)
		fmt.printf("Cannot open %s for writing\n", filename)
		return IniError.IO_Error
	}
	defer os.close(fp)

	n: int
	for section_name, &section_data in ini {
		n = fmt.fprintf(fp, "[%s]\n", section_name)
		if n < 0 do return IniError.IO_Error
		for key, &val in section_data {
			n = fmt.fprintf(fp, "%s = %s\n", key, val)
			if n < 0 do return IniError.IO_Error
		}
		n = fmt.fprintf(fp, "\n")
		if n < 0 do return IniError.IO_Error
	}
	return IniError.Ok
}
