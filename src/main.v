module main

import walkingdevel.vxml
import os

struct XMLWrap {
	nodes []&vxml.Node
mut:
	current_idx int = -1
}

fn (n XMLWrap) filter_by_predicate(name string) ?XMLWrap {
	for nnode in n.nodes {
		pnodes := nnode.get_elements_by_predicate(fn [name] (node &vxml.Node) bool {
			return node.name == name
		})

		return XMLWrap{
			nodes: pnodes
		}
	}
	return none
}

fn (n XMLWrap) get_attribute(name string) !string {
	return n.nodes.first().attributes[name]
}

fn (n XMLWrap) get_params() ?XMLWrap {
	for nnode in n.nodes {
		pnodes := nnode.get_elements_by_predicate(fn (node &vxml.Node) bool {
			return node.name == 'parameter'
		})

		return XMLWrap{
			nodes: pnodes
		}
	}
	return none
}

fn (mut n XMLWrap) next() ?&vxml.Node {
	n.current_idx++
	if n.current_idx >= n.nodes.len {
		return none
	}
	return n.nodes[n.current_idx]
}

struct GtkIRNamespace {
	name         string
	package_name string
	path         string
	includes     []string
	version      string
	parsed       vxml.Node
}

fn (g GtkIRNamespace) filter_by_class_name(name string) ?XMLWrap {
	classes := g.parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'class'
	})
	for cls in classes {
		if cls.attributes['name'] == name {
			return XMLWrap{
				nodes: [cls]
			}
		}
	}
	if name == '' {
		return XMLWrap{
			nodes: classes
		}
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

fn translate_ctype_to_v(typ string) string {
	return match typ {
		'const char*' { '&char' }
		else { typ }
	}
}

fn main() {
	gir_p := new_parser() or { panic(err) }
	app := gir_p.root.filter_by_class_name('Application') or { return }
	cons := app.filter_by_predicate('constructor') or { return }
	typ := cons.get_attribute('c:identifier')!
	ret_typ := cons.filter_by_predicate('return-value')?.filter_by_predicate('type')?.get_attribute('c:type')!
	ret_type := '&C.${ret_typ.replace('*', '')}'
	mut param_str := ''
	params := cons.get_params()?
	for i, param in params {
		param_str += param.get_attribute('name')! + ' '
		typ2 := param.get_element_by_tag_name('type')!
		param_str += translate_ctype_to_v(typ2.attributes['c:type'])
		if i < params.nodes.len - 1 {
			param_str += ', '
		}
	}
	println('fn C.${typ}(${param_str}) ${ret_type}')
}
