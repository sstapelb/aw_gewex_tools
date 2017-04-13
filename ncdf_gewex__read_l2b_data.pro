
function ncdf_gewex::read_l2b_data, file, node=node, variables = variables, found = found

	vars   = keyword_set(variables) ? variables				: *self.variables
	nod    = keyword_set(node) 		? strlowcase(node[0]) 	: 'asc'
	out    = hash()

	;clara has separate files for each parameter
	if ~self.clara2 and ~self.hector then fileID = ncdf_open(file[0])

	found  = 0
	foreach prd, vars.keys() do begin

		vn         = vars[prd].var
		pname      = vars[prd].path
		unit_scale = vars[prd].unit_scale

		if self.clara2 or self.hector then begin
			dum_file = file_search(strjoin(strsplit(file,strupcase(self.default_var),/ext,/regex),pname),count=count_file)
			if count_file eq 0 then continue
			fileID = ncdf_open(dum_file[0])
		endif
		
		varID = NCDF_Varid(fileID,vn+'_'+nod)
		if varID ne -1 then begin
			NCDF_Varget, fileID, varID, dummy
			NCDF_AttGet, fileID, varID, '_FillValue', fillv
			if size(dummy,/type) gt 1 then begin
				NCDF_AttGet, fileID, varID, 'scale_factor', scale
				NCDF_AttGet, fileID, varID, 'add_offset'  , offset
			endif else begin
				scale  = 1.
				offset = 0.
			endelse
			; scale+offset 
			idx  = where(dummy eq fillv[0], n_miss)
			data = temporary(dummy) * float(scale[0]) + float(offset[0])
			if keyword_set(unit_scale) then data *= float(unit_scale[0])
			if n_miss gt 0 then data[idx] = -999.
			undefine, unit_scale
			
			if ( prd eq 'ILLUM' and strupcase(vn) eq 'SUNZEN' and (self.clara2) ) then begin
				; clara has no illum included, we have to build it from sunzen
				illum = data * 0. -999.
				illum[WHERE(between(data, 0., 75.,/not_include_upper))] = 1	; Day
				illum[WHERE(between(data,75., 95.,/not_include_upper))] = 2	; Twilight
				illum[WHERE(between(data,95.,180.))] = 3					; Night
				data = illum
				undefine, illum
			endif

			out[prd] = temporary(data)
			if self.clara2 or self.hector then NCDF_CLOSE, fileID
		endif
	endforeach

	if ~self.clara2 and ~self.hector then NCDF_CLOSE, fileID

	found = (n_elements(out) eq n_elements(vars))

	return, out
end
