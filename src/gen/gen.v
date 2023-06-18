module main

// import walkingdevel.vxml
import os
import regex

// Arch Linx Paths
#pkgconfig gtk4
#flag -I /usr/lib/graphene-1.0/include
#include "gtk/gtk.h"

fn C.gtk_application_new(id &char, flags int) &C.GtkApplication

fn C.gtk_application_window_new(app C.GtkApplication) &C.GtkWindow

fn C.gtk_window_set_default_size(win C.GtkWindow, w int, h int)

fn C.gtk_window_set_title(win C.GtkWindow, title &char)

fn C.gtk_container_add(container voidptr, widget voidptr)

fn C.gtk_widget_show(win C.GtkWindow)

fn C.g_signal_connect(ins voidptr, signal &char, cb voidptr, data voidptr)

fn C.gtk_widget_destroy(widget voidptr)

fn C.gtk_widget_grab_focus(widget voidptr)

fn C.g_application_run(app C.GtkApplication, argc int, argv int) int

fn activate_cb(app &C.GtkApplication, data voidptr) {
	win := C.gtk_application_window_new(app)
	C.gtk_window_set_default_size(win, 1000, 600)
	C.gtk_window_set_title(win, &char('hello'.str))
	C.gtk_widget_show(win)
}

struct GtkIRNamespace {
	name     string
	path     string
	includes []string
}

type Imports = []GtkIRNamespace

fn (i Imports) has_import(path string) bool {
	for v in i {
		if path in v.includes {
			return true
		}
	}
	return false
}

struct Parser {
	imports Imports
}

fn (p Parser) unique_imports() []string {
	mut imps := []string{}
	for i in p.imports {
		for j in i.includes {
			if j in imps {
				continue
			}
			imps << j
		}
	}
	return imps
}

fn package_name_from_file(content string) !string {
	query := r'package name="(?P<name>\w+)"'
	mut re := regex.new()
	re.compile_opt(query)!
	mut name := ''
	for elem in re.find_all_str(content) {
		re.match_string(elem)
		name = re.get_group_by_name(elem, 'name')
	}
	return name
}

fn includes_from_file(content string) ![]string {
	query := r'include name="(?P<name>\w+)" version="(?P<version>[\w\.]+)"'
	mut re := regex.new()
	re.compile_opt(query)!
	mut includes := []string{}
	for elem in re.find_all_str(content) {
		re.match_string(elem)
		name := re.get_group_by_name(elem, 'name')
		version := re.get_group_by_name(elem, 'version')
		includes << '/usr/share/gir-1.0/${name}-${version}.gir'
	}
	return includes
}

fn recurse_imports(mut imports Imports, start GtkIRNamespace) !Imports {
	imports << start
	for v in start.includes {
		content := os.read_file(v)!
		includes := includes_from_file(content)!
		pname := package_name_from_file(content)!
		tmp := GtkIRNamespace{
			name: pname
			path: v
			includes: includes
		}
		for i in includes {
			if imports.has_import(i) {
				continue
			}
			recurse_imports(mut imports, tmp)!
		}
	}
	return imports
}

fn new_parser() !&Parser {
	gir := new_gtk_ir_namespace('/usr/share/gir-1.0/Gtk-4.0.gir')!
	mut imps := Imports([]GtkIRNamespace{})
	imps = recurse_imports(mut imps, gir)!
	return &Parser{
		imports: imps
	}
}

fn new_gtk_ir_namespace(path string) !&GtkIRNamespace {
	content := os.read_file(path)!
	includes := includes_from_file(content)!
	pname := package_name_from_file(content)!
	return &GtkIRNamespace{
		name: pname
		path: path
		includes: includes
	}
}

fn main() {
	gir_p := new_parser() or { panic(err) }
	println(gir_p.unique_imports())

	// for v in posts[0].children {
	// 	if v.name == 'include' {
	// 		println('/usr/share/gir-1.0/${v.attributes['name']}-${v.attributes['version']}')
	// 	}
	// 	// if v.name == 'namespace' {
	// 	// 	for v2 in v.children {
	// 	// 		println(v2.attributes)
	// 	// 		println(v2.name)
	// 	// 	}
	// 	// }
	// }

	// app := C.gtk_application_new(&char('org.gtk.example'.str), C.G_APPLICATION_DEFAULT_FLAGS)
	// C.g_signal_connect(app, &char('activate'.str), activate_cb, unsafe { nil })
	// status := C.g_application_run(app, 0, 0)
}
