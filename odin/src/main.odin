package iniparser

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"

main :: proc() {
	argv: []string = os.args
	infile, outfile: string
	/*
	debug := false;
	if debug do argv = []string{"./iniparser", "input.ini"}
	else do argv = os.args
	*/

	if len(argv) < 2 {
		path_parts := strings.split(argv[0], "/")
		fmt.printf("usage: %s <input.ini> [<output.ini>]\n", path_parts[len(path_parts) - 1] )
		os.exit(1)
	} else if len(argv) < 3 {
		infile = argv[1]
		outfile = ""
	} else {
		infile = argv[1]
		outfile = argv[2]
	}

	handle, err_open := os.open(argv[1], os.O_RDONLY, 0)
	if err_open != os.ERROR_NONE {
		fmt.printf("Cannot open %s\n", argv[1])
		os.exit(1)
	}
	defer os.close(handle)
	
	stream := os.stream_from_handle(handle)
	defer io.close(stream)
	
	ini, err_parse_ini := parse_ini_stream(stream)
	if err_parse_ini != IniError.Ok {
		fmt.printf("Ini parsing failed: %s\n", ini_error_to_string(err_parse_ini))
		os.exit(1)
	}

	// Print the whole INI structure
	fmt.printf("\nShowing parsed INI:\n")
	ini_print(&ini)


	// ini_get (NULL)
	fmt.printf("\nini_get(NULL, \"abc\", \"def\"): %s\n", ini_get(nil, "abc", "def"))

	val, val2: string
	val3, val4: ^string

	// ini_get (x)
	val = ini_get(&ini, "first", "name")
	fmt.printf("\nValue for [first] name = |%s|\n", val)
	val = "LALA 1"
	val2 = ini_get(&ini, "first", "name")
	fmt.printf("Value after assigning new value to a non-ref -> [first] name = |%s|\n", val2)

	// ini_get_ref (x)
	val3 = ini_get_ref(&ini, "first", "surname")
	fmt.printf("\nValue for [first] surname = |%s|\n", val3^)
	val3^ = "LALA 2"
	val4 = ini_get_ref(&ini, "first", "surname")
	fmt.printf("Value after manually assigning new value -> [first] surname = |%s|\n", val3^)

	// ini_set (x)
	ini_set(&ini, "first", "surname", "LALA 3")
	val4 = ini_get_ref(&ini, "first", "surname")
	fmt.printf("Value after assigning new value through func -> [first] surname = |%s|\n", val4^)

	// Display
	fmt.printf("\n\nPrint after set:\n")
	ini_print(&ini)

	// Get nonexistent
	fmt.printf("\nTrying to get a nonexistent key in a nonexistent section: |%s|\n",
		ini_get(&ini, "0xbabadeda", "keke"))

	// Set nonexistent
	fmt.printf("\nTrying to create a nonexistent key in an nonexistent section ([random section] lalala)...\n")
	ini_set(&ini, "random section", "lalala", "trol")

	// Final display
	fmt.printf("\nAfter modifications:\n")
	ini_print(&ini)

	// Save from memory to file if specified
	if len(outfile) > 0 {
		fmt.printf("\nSaving to %s...\n", outfile)
		err_save := ini_save(&ini, outfile)
		if err_save != IniError.Ok {
			fmt.printf("\nSaving failed (%s)\n", ini_error_to_string(err_save))
		}
	}

	// Free
	fmt.printf("\nDestroying INI structure..\n")
	ini_destroy(&ini)
	
	fmt.printf("\nDone.\n")
}
