"
" Plugin: dirsettings
"
" Version: 1.0
"
" Description:
"
"   This is a simple plugin that allows per directory settings for your
"   favourite editor VIM. This plugin is mainly inspired by the already
"   existing plugin named dirsettings, see:
"
"   http://www.vim.org/scripts/script.php?script_id=1860
"
"   But this plugin goes a little step further. It walks the whole directory
"   tree up to the root and on its way back it sources each found ".vimrc".
"   This allows to overwrite specific settings even in subdirectories which
"   inherit the settings of each parent directory. Furthermore if a .vim
"   folder is found in one of the parent directories it is added to the
"   runtime path and therefore treated as the .vim folder inside the home dir.
"
"   Additionally it checks for a ".vim/tags" file and appends it to the tag
"   list. This is better than a "tags" file in the current working directory
"   for source control reasons.
"
"   See readme.rst for details.
"
" Author: Christian Hammerl <info@christian-hammerl.de>
" Author: Jakob Westhoff <jakob@qafoo.com>
"

if (exists('g:dirsettings_loaded'))
	finish
endif
let g:dirsettings_loaded = 1

function dirsettings#Install(...)
	let l:fname = a:0 > 0 ? a:1 : '.vimrc'
	let l:dname = a:0 > 1 ? a:2 : '.vim'
	let l:augroup = a:0 > 2 ? a:3 : 'dirsettings'
	let l:rootpath = a:0 > 3 ? a:4 : ''

	execute 'augroup ' . l:augroup
		au!
		execute 'au BufNewFile * : call s:PrepareBuffer(''BufNewFile'', ''' . l:fname . ''', ''' . l:dname . ''', ''' . l:rootpath . ''')'
		execute 'au BufReadPre * : call s:PrepareBuffer(''BufReadPre'', ''' . l:fname . ''', ''' . l:dname . ''', ''' . l:rootpath . ''')'
	augroup END
endfunction

function s:PrepareBuffer(event, fname, dname, rootpath)
	if (exists('b:dirsettings_prepared'))
		return
	endif

	let b:dirsettings_prepared = 1

	call s:LoadDirectorySettings(function('s:ApplyLocalConfiguration'), a:fname, a:dname, a:rootpath, substitute($HOME, '/\+$', '', ''))
	execute 'doautocmd ' . a:event . ' <buffer>'
endfunction

function s:LoadDirectorySettings(callback, fname, dname, rootpath, home, ...)
	let l:here = substitute(a:0 > 0 ? a:1 : expand('%:p:h'), '/\+$', '', '')

	let l:lastSegmentStart = match(l:here, '/[^/]\+$')
	let l:isHomeDirectory = (stridx(l:here, a:home) == 0 && strlen(l:here) == strlen(a:home)) ? 1 : 0

	if (l:lastSegmentStart > -1 && l:here != a:rootpath)
		call s:LoadDirectorySettings(a:callback, a:fname, a:dname, a:rootpath, a:home, strpart(l:here, 0, l:lastSegmentStart))
	endif

	if (!l:isHomeDirectory)
		call a:callback(a:fname, a:dname, l:here)
	endif
endfunction

function s:ApplyLocalConfiguration(fname, dname, path)
	let l:fullfname = a:path . '/' . a:fname
	let l:fulldname = a:path . '/' . a:dname
	let l:fulltagname = a:path . '/' . a:dname . '/tags'

	if (isdirectory(l:fulldname))
		execute "set runtimepath+=" . l:fulldname
	endif
	if (filereadable(l:fullfname))
		exec 'source ' . l:fullfname
	endif
	if (filereadable(l:fulltagname))
		exec 'set tags +=  ' . l:fulltagname
	endif 
endfunction

