function! vim_plugin#DisplayTime()
	echo "Ora attuale: " . strftime("%H:%M:%S")
    "if a:0 > 0 && (a:1 == "d" || a:1 == "t")
    "    if a:1 == "d"
    "        echo strftime("%b %d")
    "    elseif a:1 == "t"
    "        echo strftime("%H:%M")
    "    endif
    "else
    "    echo strftime("%b %d %H:%M")
    "endif
endfunction


" Starts a section for Python 3 code.
python3 << EOF
# Imports Python modules to be used by the plugin.
import vim, re
import json, requests, os, pathlib, sys
import MySQLdb
sys.path.append("/home/marco/Documenti/coding/python/modules")
from mlatexParser import Parser


#plugin_path = os.path.dirname(vim.eval("expand('%:p')"))
plugin_path= '/home/marco/vim-plugin'
json_path = os.path.join(plugin_path, 'access_db.json')
# Leggi le credenziali dal file JSON
credentials= {}

with open(json_path) as f:
    credentials = json.load(f)

# Connetti al database
connection = MySQLdb.connect(
    host=credentials["host"],
    user=credentials["user"],
    passwd=credentials["password"],
    db=credentials["database"]
)
keys_struct= [
	'axiom',
	'math_def',
	'oss',
	'affermazione',
	'dimostrazione'
]

def Convert():
	# Crea un cursore
	cursor = connection.cursor()

	query = "SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name = 'nodi' AND table_schema = 'grafo_mat'"

	# Esegui la query
	cursor.execute(query)

	# Ottieni il risultato
	auto_increment_value = cursor.fetchone()[0]

	#print('\n'.join(vim.current.buffer[:]))
	p= Parser('\n'.join(vim.current.buffer[:]), auto_increment_value)

	vim.current.buffer[:]= p.nodi[0].split('\n')
	
	try:
		# Esegui una query SQL
		for i in range(1,len(p.nodi_names)):
			#print(p.nodi_names[i], p.nodi[i])
			struct= p.nodi_names[i]
			content= p.nodi[i]
			#print(f"INSERT INTO nodi (struct, content) VALUES ('{struct}','{content}')")
			cursor.execute("INSERT INTO nodi (struct, content) VALUES (%s,%s)", (struct, content))

		connection.commit()
	finally:
		# Chiudi la connessione
		cursor.close()
def parseInt(stringa):
	# Utilizza una regex per trovare tutti i numeri nella stringa
	numeri = re.findall(r'\d+', stringa)
	s= ''
	for numero in numeri:
		s+= numero
	return int(s)

def Compile():
	content= '\n'.join(vim.current.buffer[:])
	file_name = pathlib.Path(vim.eval("expand('%:p')")).stem+".tex"

	matches= re.findall(r'\\nodeServer\{\d+\}', content)
	ids= []
	for match in matches:
		ids.append(parseInt(match))

	cursor = connection.cursor()
	data= []
	try:
		# Esegui una query SQL
		for i in ids:
			cursor.execute("SELECT struct,content FROM nodi WHERE id="+str(i))
			res= cursor.fetchone()
			data.append((i, '\\begin{'+res[0]+'}'+res[1]+'\end{'+res[0]+'}'))
		cursor.close()
	finally:
		cursor.close()
	
	for data_o in data:
		i, con= data_o
		content= content.replace('\\nodeServer{'+str(i)+'}', con)
	# Open a file in write mode ('w' for write)
	file = open("tmp/"+file_name, 'w')

	# Write content to the file
	file.write(content)

	# Close the file
	file.close()
def AllUpper():
	content= vim.current.buffer[:]

	content_upper= [line.upper() for line in content]

	vim.current.buffer[:]= content_upper

EOF

function! vim_plugin#AspellCheck()
    let cursorWord = expand('<cword>')
    let aspellSuggestions = system("echo '" . cursorWord . "' | aspell -a")
    let aspellSuggestions = substitute(aspellSuggestions, "& .* 0:", "", "g")
    let aspellSuggestions = substitute(aspellSuggestions, ", ", "\n", "g")
    echo aspellSuggestions
endfunction

function! s:init_compiler(options) abort " {{{1
	"if type(g:vimtex_compiler_method) == v:t_func
	"	\ || exists('*' . g:vimtex_compiler_method)
	"	let l:method = call(g:vimtex_compiler_method, [a:options.state.tex])
	"else
	"	let l:method = g:vimtex_compiler_method
	"endif

	"if index([
	"		\ 'arara',
	"		\ 'generic',
	"		\ 'latexmk',
	"		\ 'latexrun',
	"		\ 'tectonic',
	"	\], l:method) < 0
	"	call vimtex#log#error('Error! Invalid compiler method: ' . l:method)
	"	let l:method = 'latexmk'
	"endif
	let l:method= 'latexmk'
	let l:options =
		\ get(g:, 'vimtex_compiler_' . l:method, {})
	"	\ get(g:, 'vimtex_compiler_' . l:method, {})
	let l:options = extend(deepcopy(l:options), a:options)
	let l:compiler
		\ = vimtex#compiler#{l:method}#init(l:options)
	return l:compiler
endfunction

" }}}1


function! vim_plugin#MarcoCompile()
	if !b:vimtex.compiler.enabled
		echo "Vimtex Compiler not enabled"
		return
	endif
"	python3 Convert()
	python3 Compile()
	let full_filename = expand("%:t") " Ottieni il nome del file con estensione
	let l:base_filename = substitute(full_filename, '\.\w\+$', '', '') " Rimuovi l'estensione
	"echo base_filename.".ctex"

	if !filereadable(base_filename.".ctex")
		return
	endif
	" Respect the compiler out_dir option
	if empty(b:vimtex.compiler.out_dir)
		let l:out_dir = b:vimtex.root
		let l:out_dir = vimtex#paths#is_abs(b:vimtex.compiler.out_dir)
			\ ? b:vimtex.compiler.out_dir
			\ : b:vimtex.root . '/' . b:vimtex.compiler.out_dir
	endif
	" Write content to temporary file
	let l:out_dir= expand('%:p:h')

	let l:file = {}
	let l:file.base = l:base_filename
	let l:file.root = l:out_dir
	let l:file.tex = l:out_dir . '/tmp/' . l:file.base . '.tex'
	let l:file.pdf = l:out_dir . '/' . l:file.base . '.pdf'
	let l:file.log = l:out_dir . '/' . l:file.base . '.log'
	let l:file.base .= '.tex'


	if empty(l:file) | return | endif
	let l:tex_program = b:vimtex.get_tex_program()
	let l:file.get_tex_program = {-> l:tex_program}

	" Create and initialize temporary compiler
	let l:compiler = s:init_compiler({
		\ 'state': l:file,
		\ 'out_dir': '',
		\ 'continuous': 0,
		\ 'callback': 0,
	\})
	if empty(l:compiler) | return | endif

	call vimtex#log#info('Compiling selected lines ...')
	"call vimtex#log#set_silent()
	call l:compiler.start()
	call l:compiler.wait()

	" Check if successful
	if vimtex#qf#inquire(l:file.tex)
		call vimtex#log#set_silent_restore()
		call vimtex#log#warning('Custom Compiling ... failed!')
		botright cwindow
		return
	else
		call l:compiler.clean(0)
		"call b:vimtex.viewer.view(l:file.pdf)
		call vimtex#log#set_silent_restore()
		call vimtex#log#info('Custom Compiling ... done')
	endif
endfunction

