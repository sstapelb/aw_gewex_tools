
function read_level2b_data, file, node=node, variables=variables, found=found

	dprd   = keyword_set(day_products)
	vn     = keyword_set(variables) ? strlowcase(variables)	: ['ctp','cot','cer','cph','cth','cee','ctt','cmask','cwp','illum']
	nod    = keyword_set(node) 	? strlowcase(node[0]) 	: 'asc'
	fileID = ncdf_open(file)

	found  = 0
	for dd = 0, n_elements(vn) -1 do begin
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
			if n_miss gt 0 then data[idx] = -999.

			case vn[dd] of
				'illum'	: struct = n_elements(struct) eq 0 ? {illum:temporary(data)}	: create_struct(struct,'illum',temporary(data))
				'ctp' 	: struct = n_elements(struct) eq 0 ? {ctp:temporary(data)}	: create_struct(struct,'ctp',temporary(data))
				'cot' 	: struct = n_elements(struct) eq 0 ? {cod:temporary(data)}	: create_struct(struct,'cod',temporary(data))
				'cer' 	: struct = n_elements(struct) eq 0 ? {ref:temporary(data)}	: create_struct(struct,'ref',temporary(data))
				'cth'	: struct = n_elements(struct) eq 0 ? {cz:temporary(data)}	: create_struct(struct,'cz' ,temporary(data))
				'cee'	: struct = n_elements(struct) eq 0 ? {cem:temporary(data)}	: create_struct(struct,'cem',temporary(data))
				'cph' 	: struct = n_elements(struct) eq 0 ? {cph:temporary(data)}	: create_struct(struct,'cph',temporary(data))
				'ctt' 	: struct = n_elements(struct) eq 0 ? {ct:temporary(data)}	: create_struct(struct,'ct' ,temporary(data))
				'cmask'	: struct = n_elements(struct) eq 0 ? {ca:temporary(data)}	: create_struct(struct,'ca' ,temporary(data))
				'cwp' 	: struct = n_elements(struct) eq 0 ? {cwp:temporary(data)}	: create_struct(struct,'cwp',temporary(data))
				'cem'	: struct = n_elements(struct) eq 0 ? {cem:temporary(data)}	: create_struct(struct,'cem',temporary(data))
				else 	: struct = n_elements(struct) eq 0 ? {var0:temporary(data)}	: create_struct(struct,'var'+strcompress(dd,/rem),temporary(data))
			endcase
			found ++
		endif
	endfor

	NCDF_CLOSE, fileID

	found = (found eq n_elements(vn))

	return, (n_elements(struct) eq 0 ? -1 : struct)

end
