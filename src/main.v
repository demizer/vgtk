module main

import walkingdevel.vxml
import os
import regex

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
		// TODO: only read first 10kb of the file to make it faster
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
	// gir_p := new_parser() or { panic(err) }
	// println(gir_p.unique_imports())
	//
	ggir := vxml.parse_file('/usr/share/gir-1.0/Gtk-4.0.gir') or { panic(err) }

	classes := ggir.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'class'
	})

	// println(posts.first().get_text())
	for cls in classes {
		// println('mac: ${mac}')
		name := cls.attributes['name']
		typ := cls.attributes['c:type']
		// println('name: ${name}')
		// println('type: ${typ}')
		if name == 'Application' {
			// println(cls.children)
			cons := cls.get_elements_by_predicate(fn (node &vxml.Node) bool {
				return node.name == 'constructor'
			})
			ret_type := '&C.${typ}'
			mut param_str := ''
			params := cons[0].children.last().children
			for i, param in params {
				param_str += param.attributes['name'] + ' '
				typ2 := param.children.last()
				param_str += match typ2.attributes['c:type'] {
					'const char*' { '&char' }
					else { typ2.attributes['c:type'] }
				}
				if i < params.len - 1 {
					param_str += ', '
				}
			}
			print('fn C.${cons[0].attributes['c:identifier']}(${param_str}) ${ret_type}')
		}
	}

	// output the file

	// TODO
}
