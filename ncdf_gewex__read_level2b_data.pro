
function ncdf_gewex::read_level2b_data, file, node=node, variables = variables, found = found

	vn     = keyword_set(variables) ? strlowcase(variables)	: ['ctp','cot','cer','cph','cth','cee','ctt','cmask','cwp','illum']
	nod    = keyword_set(node) 	? strlowcase(node[0]) 		: 'asc'
	
	if self.algo ne 'CLARA_A2' then fileID = ncdf_open(file[0])

	found  = 0
	for dd = 0, n_elements(vn) -1 do begin
		if self.algo eq 'CLARA_A2' then begin
			case vn[dd] of
				'sunzen'	: fname = 'CAA'
				'ctp' 		: fname = 'CTO'
				'cth'		: begin & fname = 'CTO' & unit_scale =     0.001 & end
				'ctt' 		: fname = 'CTO'
				'cot' 		: fname = 'CWP'
				'ref' 		: begin & fname = 'CWP' & unit_scale = 1000000.0 & end
				'cwp' 		: begin & fname = 'CWP' & unit_scale =    1000.0 & end
				'cph' 		: fname = 'CPH'
				'cc_mask'	: fname = 'CMA'
				else 		: fname = ''
			endcase
			dum_file = file_search(strjoin(strsplit(file,strupcase(self.clara_default_var),/ext,/regex),fname),count=count_file)
			if count_file eq 0 then continue
			fileID = ncdf_open(dum_file[0])
		endif
		varID = NCDF_Varid(fileID,vn[dd]+'_'+nod)
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
			idx  = where(dummy eq fillv[0], n_miss)
			data = dummy * float(scale[0]) + float(offset[0])
			if keyword_set(unit_scale) then data = data * unit_scale[0]
			if n_miss gt 0 then data[idx] = -999.
			undefine, unit_scale

			case vn[dd] of
				'illum'	: struct = n_elements(struct) eq 0 ? {illum:temporary(data)}: create_struct(struct,'illum',temporary(data))
				'sunzen': struct = n_elements(struct) eq 0 ? {sunza:temporary(data)}: create_struct(struct,'sunza',temporary(data))
				'ctp' 	: struct = n_elements(struct) eq 0 ? {ctp:temporary(data)}	: create_struct(struct,'ctp',temporary(data))
				'cot' 	: struct = n_elements(struct) eq 0 ? {cod:temporary(data)}	: create_struct(struct,'cod',temporary(data))
				'cer' 	: struct = n_elements(struct) eq 0 ? {ref:temporary(data)}	: create_struct(struct,'ref',temporary(data))
				'ref' 	: struct = n_elements(struct) eq 0 ? {ref:temporary(data)}	: create_struct(struct,'ref',temporary(data))
				'cth'	: struct = n_elements(struct) eq 0 ? {cz:temporary(data)}	: create_struct(struct,'cz' ,temporary(data))
				'cee'	: struct = n_elements(struct) eq 0 ? {cem:temporary(data)}	: create_struct(struct,'cem',temporary(data))
				'cem'	: struct = n_elements(struct) eq 0 ? {cem:temporary(data)}	: create_struct(struct,'cem',temporary(data))
				'cph' 	: struct = n_elements(struct) eq 0 ? {cph:temporary(data)}	: create_struct(struct,'cph',temporary(data))
				'ctt' 	: struct = n_elements(struct) eq 0 ? {ct:temporary(data)}	: create_struct(struct,'ct' ,temporary(data))
				'cmask'	: struct = n_elements(struct) eq 0 ? {ca:temporary(data)}	: create_struct(struct,'ca' ,temporary(data))
				'cc_mask': struct = n_elements(struct) eq 0 ? {ca:temporary(data)}	: create_struct(struct,'ca' ,temporary(data))
				'cwp' 	: struct = n_elements(struct) eq 0 ? {cwp:temporary(data)}	: create_struct(struct,'cwp',temporary(data))
				else 	: struct = n_elements(struct) eq 0 ? {var0:temporary(data)}	: create_struct(struct,'var'+strcompress(dd,/rem),temporary(data))
			endcase
			found ++
		endif
	endfor

	NCDF_CLOSE, fileID

	found = (found eq n_elements(vn))

	return, (n_elements(struct) eq 0 ? -1 : struct)

end
