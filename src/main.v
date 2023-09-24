module main

import walkingdevel.vxml
import os

struct GtkIRNamespace {
	name         string
	package_name string
	path         string
	includes     []string
	version      string
	parsed       vxml.Node
}

fn (g GtkIRNamespace) filter_by_class_name(name string) ?[]&vxml.Node {
	classes := g.parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'class'
	})
	for cls in classes {
		if cls.attributes['name'] == name {
			return [cls]
		}
	}
	if name == '' {
		return classes
	}
	return none
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
	root    GtkIRNamespace
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

fn recurse_imports(mut imports Imports, start GtkIRNamespace) !Imports {
	imports << start
	for v in start.includes {
		// TODO: only read first 10kb of the file to make it faster
		if !os.exists(v) {
			eprintln('import: ${v} does not exist! Skipping')
			continue
		}
		tmp := new_gir_namespace(v)!
		for i in tmp.includes {
			if imports.has_import(i) {
				continue
			}
			recurse_imports(mut imports, tmp)!
		}
	}
	return imports
}

fn new_parser() !&Parser {
	gir := new_gir_namespace('/usr/share/gir-1.0/Gtk-4.0.gir')!
	// println(gir)
	// mut imps := Imports([]GtkIRNamespace{})
	// imps = recurse_imports(mut imps, gir)!
	return &Parser{
		root: gir
		// imports: imps
	}
}

fn new_gir_namespace(path string) !&GtkIRNamespace {
	parsed := vxml.parse_file(path)!
	pincludes := parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'include'
	})
	mut includes := []string{}
	for i in pincludes {
		name := i.attributes['name']
		version := i.attributes['version']
		includes << '/usr/share/gir-1.0/${name}-${version}.gir'
	}
	pname := parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'namespace'
	})
	ppackage := parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'package'
	})
	return &GtkIRNamespace{
		name: pname.first().attributes['name']
		version: pname.first().attributes['version']
		package_name: ppackage.first().attributes['name']
		path: path
		parsed: parsed
		includes: includes
	}
}

fn main() {
	gir_p := new_parser() or { panic(err) }
	println(gir_p.root.filter_by_class_name('Label'))

	// // println(posts.first().get_text())
	// for cls in classes {
	// 	// println('mac: ${mac}')
	// 	name := cls.attributes['name']
	// 	typ := cls.attributes['c:type']
	// 	// println('name: ${name}')
	// 	// println('type: ${typ}')
	// 	if name == 'Application' {
	// 		// println(cls.children)
	// 		cons := cls.get_elements_by_predicate(fn (node &vxml.Node) bool {
	// 			return node.name == 'constructor'
	// 		})
	// 		ret_type := '&C.${typ}'
	// 		mut param_str := ''
	// 		params := cons[0].children.last().children
	// 		for i, param in params {
	// 			param_str += param.attributes['name'] + ' '
	// 			typ2 := param.children.last()
	// 			param_str += match typ2.attributes['c:type'] {
	// 				'const char*' { '&char' }
	// 				else { typ2.attributes['c:type'] }
	// 			}
	// 			if i < params.len - 1 {
	// 				param_str += ', '
	// 			}
	// 		}
	// 		print('fn C.${cons[0].attributes['c:identifier']}(${param_str}) ${ret_type}')
	// 	}
	// }

	// output the file

	// TODO
}
