pl-deadlines.js: pl-deadlines.bc all-tz.js events.js
	js_of_ocaml +gen_js_api/ojs_runtime.js +base/runtime.js +core_kernel/runtime.js +bigstring-base_bigstring.js +time_now/runtime.js +timezone/runtime.js --extern-fs -o pl-deadlines.js pl-deadlines.bc

pl-deadlines.bc: today.ml pl-deadlines.ml
	ocamlfind ocamlc -package ezjsonm -package core_kernel -package ocaml-vdom -package timezone -no-check-prims -linkpkg -o pl-deadlines.bc today.ml pl-deadlines.ml

today.ml:
	ocaml configure.ml

events.js: events.json
	jsoo_fs -o events.js -I . events.json

all-tz.js:
	grep -r TZif /usr/share/zoneinfo -l | xargs -n 1 -I {} echo {}:{} | xargs jsoo_fs -o all-tz.js

all: pl-deadlines.js

clean:
	rm -f pl-deadlines.js pl-deadlines.bc today.ml *.cmi *.cmo today.ml events.js all-tz.js
