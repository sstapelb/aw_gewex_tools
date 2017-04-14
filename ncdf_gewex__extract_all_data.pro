;   $Id:$
;  reads all products in hash tables
;
;  requires much memory
;
;  all results are written in "out" hash variable
;
;
FUNCTION ncdf_gewex::extract_all_data, file, node = node

	; now day products are always processed except for '0130' and '1930'
	; define otherwise at ncdf_gewex::update in ncdf_gewex__define.pro
	incl_day  = self.process_day_prds
	proc_list = strupcase(*self.all_prd_list)

	nlon = long(360./self.resolution)
	nlat = long(180./self.resolution)
	MISSING = self.missing_value[0]

	out = orderedhash() ; orderedhash is important! CA needs to be created before all CAE prd's

	l2b_data = self.read_l2b_data(file, node = node, found = found_all)
	if not found_all then begin
		print,'ncdf_gewex::extract_all_data: Not all defined variable names could be read! Check "self.all_prd_list" and "get_l2b_varnames"!'
		stop
	endif

	if l2b_data.haskey('CMASK') then ca    = l2b_data.remove('CMASK')
	if l2b_data.haskey('CER')	then ref   = l2b_data.remove('CER')
	if l2b_data.haskey('ILLUM')	then illum = l2b_data.remove('ILLUM')
	if l2b_data.haskey('CTP')	then ctp   = l2b_data.remove('CTP')
	if l2b_data.haskey('CTH')	then cth   = l2b_data.remove('CTH')
	if l2b_data.haskey('CTT')	then ct    = l2b_data.remove('CTT')
	if l2b_data.haskey('COT')	then cod   = l2b_data.remove('COT')
	if l2b_data.haskey('CWP')	then cwp   = l2b_data.remove('CWP')
	if l2b_data.haskey('CPH')	then cph   = l2b_data.remove('CPH')
	if l2b_data.haskey('CEE')	then cem   = l2b_data.remove('CEE')
	if l2b_data.haskey('SZA')	then sol   = l2b_data.remove('SZA')
	
	; height levels as mask
	if is_defined(ctp) then ctp_l = between(ctp,680.,1100.)
	if is_defined(ctp) then ctp_m = between(ctp,440., 680.,/not_include_upper)
	if is_defined(ctp) then ctp_h = between(ctp,  0., 440.,/not_include_upper)

	; phase as mask (water and ice)
	; stapel cci cph has 0,1,2 := clear,liquid,ice
	if is_defined(cph) then cph_w = cph eq 1
	if is_defined(cph) then cph_i = cph eq 2

	; 'CA'
	if total(proc_list eq 'CA') then begin
		val  = ca ge 0.5
		bad  = ca eq -999.
if self.famec then bad = bad OR (sol gt 70.) ; für alle einfügen und testen, ist sol gt 70 anders als illum ne 1???
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CA'] = data
	endif

	; 'CAH'
	if total(proc_list eq 'CAH') then begin
		val  = (ca ge 0.5) * ctp_h
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAH'] = data
	endif

	; 'CAM'
	if total(proc_list eq 'CAM') then begin
		val  = (ca ge 0.5) * ctp_m
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAM'] = data  
	endif

	; 'CAL'
	if total(proc_list eq 'CAL') then begin
		val  = (ca ge 0.5) * ctp_l
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAL'] = data
	endif

	; 'CAW'
	if total(proc_list eq 'CAW') then begin
		val  = (ca ge 0.5) * cph_w
		bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAW'] = data
	endif

	; 'CAI'
	if total(proc_list eq 'CAI') then begin
		val  = (ca ge 0.5) * cph_i
		bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAI'] = data
	endif

	; 'CAIH'
	if total(proc_list eq 'CAIH') then begin
		val  = (ca ge 0.5) * cph_i * ctp_h
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5)) or ((cph EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAIH'] = data
	endif

	;'CT':
	if total(proc_list eq 'CT') then begin
		val  = ct
		bad  = ct eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CT'] = data
	endif

	;'CTH':
	if total(proc_list eq 'CTH') then begin
		val  = ct  * ctp_h
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTH'] = data
	endif

	;'CTM':
	if total(proc_list eq 'CTM') then begin
		val  = ct  * ctp_m
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CTM'] = data
	endif

	;'CTL':
	if total(proc_list eq 'CTL') then begin
		val  = ct  * ctp_l
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTL'] = data
	endif

	;'CTW':
	if total(proc_list eq 'CTW') then begin
		val  = ct * cph_w
		bad  = val le 0. 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTW'] = data
	endif

	;'CTI':
	if total(proc_list eq 'CTI') then begin
		val  = ct * cph_i
		bad  = val le 0. 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTI'] = data
	endif

	;'CTIH':
	if total(proc_list eq 'CTIH') then begin
		val  = ct * cph_i * ctp_h
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTIH'] = data
	endif

	;'CP':
	if total(proc_list eq 'CP') then begin
		val  = ctp
		bad  = val eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CP'] = data
	endif

	;'CZ':
	if total(proc_list eq 'CZ') then begin
		val  = cth
		bad  = val eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CZ'] = data
	endif

	;'CEM':
	if total(proc_list eq 'CEM') then begin
		val  = cem
		bad  = cem eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEM'] = data
	endif

	;'CEMH':
	if total(proc_list eq 'CEMH') then begin
		val  = cem * ctp_h
		bad  = (cem eq -999.) or (ctp_h eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMH'] = data
	endif

	;'CEMM':
	if total(proc_list eq 'CEMM') then begin
		val  = cem * ctp_m
		bad  = (cem eq -999.) or (ctp_m eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMM'] = data
	endif

	;'CEML':
	if total(proc_list eq 'CEML') then begin
		val  = cem * ctp_l
		bad  = (cem eq -999.) or (ctp_l eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEML'] = data
	endif

	;'CEMW':
	if total(proc_list eq 'CEMW') then begin
		val  = cem * cph_w
		bad  = (cem eq -999.) or (cph_w eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CEMW'] = data
	endif

	;'CEMI':
	if total(proc_list eq 'CEMI') then begin
		val  = cem * cph_i
		bad  = (cem eq -999.) or (cph_i eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMI'] = data
	endif

	;'CEMIH':
	if total(proc_list eq 'CEMIH') then begin
		val  = cem * cph_i * ctp_h
		bad  = (cem eq -999.) or (cph_i eq 0) or (ctp_h eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMIH'] = data
	endif

	; 'CAE'
	if total(proc_list eq 'CAE') then begin
		val  = cem
		bad  = (cem eq -999.) or (ca EQ -999.)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAE'] = data
	endif

	; 'CAEH'
	if total(proc_list eq 'CAEH') then begin
		val  = cem * ctp_h
		bad  = (cem eq -999.) or (ca EQ -999.)  OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEH'] = data
	endif

	; 'CAEM'
	if total(proc_list eq 'CAEM') then begin
		val  = cem * ctp_m
		bad  = (cem eq -999.) or (ca EQ -999.)  OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEM'] = data
	endif

	; 'CAEL'
	if total(proc_list eq 'CAEL') then begin
		val  = cem * ctp_l
		bad  = (cem eq -999.) or (ca EQ -999.)  OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEL'] = data
	endif

	; 'CAEW'
	if total(proc_list eq 'CAEW') then begin
		val  =  cem  * cph_w
		bad  = (cem eq -999.) or (ca eq -999.) OR ((cph eq -999.) and (ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEW'] = data
	endif

	; 'CAEI'
	if total(proc_list eq 'CAEI') then begin
		val  = (cem > 0.) * cph_i
		bad  = (cem eq -999.) or (ca eq -999.) OR  ((cph eq -999.) and (ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEI'] = data
	endif

	; 'CAEIH'
	if total(proc_list eq 'CAEIH') then begin
		val  = (cem > 0.) * cph_i * ctp_l
		bad  = (cem eq -999.) or (ca eq -999.) OR  ((cph eq -999.) and (ca ge 0.5)) OR ((ctp EQ -999.) AND ( ca ge 0.5)) 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEIH'] = data
	endif

	; daytime products
	if incl_day then begin
		; 'CAD'
		if total(proc_list eq 'CAD') then begin
			val  = ca ge 0.5
			bad  = (ca eq -999.) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CAD'] = data
		endif

		; 'CAWD'
		if total(proc_list eq 'CAWD') then begin
			val  = (ca ge 0.5) * cph_w
			bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5))  or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CAWD'] = data
		endif

		; 'CAID'
		if total(proc_list eq 'CAID') then begin
			val  = (ca ge 0.5) * cph_i
			bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5)) or ( illum ne 1) 
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CAID'] = data
		endif

		;'COD': logarithmic space
		if total(proc_list eq 'COD') then begin
			val  = cod
			bad  = val le 0.  or ( illum ne 1 ); STAPEL 11/2013 no cod =0 allowed, because of alog
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['COD'] = data
		endif

		;'CODH':
		if total(proc_list eq 'CODH') then begin
			val  = cod * ctp_h
			bad  = val le 0. or ( illum ne 1 )
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CODH'] = data
		endif

		;'CODM':
		if total(proc_list eq 'CODM') then begin
			val  = cod * ctp_m
			bad  = val le 0. or ( illum ne 1 )
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CODM'] = data
		endif

		;'CODL':
		if total(proc_list eq 'CODL') then begin
			val  = cod * ctp_l
			bad  = val le 0. or ( illum ne 1 )
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CODL'] = data 
		endif

		;'CODW':
		if total(proc_list eq 'CODW') then begin
			val  = cod * cph_w
			bad  = val le 0. or ( illum ne 1 )
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CODW'] = data 
		endif

		;'CODI':
		if total(proc_list eq 'CODI') then begin
			val  = cod * cph_i
			bad  = val le 0. or ( illum ne 1 )
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CODI'] = data 
		endif

		;'CODIH':
		if total(proc_list eq 'CODIH') then begin
			val  = cod * cph_i * ctp_h
			bad  = val le 0. or ( illum ne 1 )
			val  = alog(val>1e-15) + 10.
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CODIH'] = data
		endif

		;'CLWP':
		if total(proc_list eq 'CLWP') then begin
			; val  = (cod>0) * (ref>0) * cph_w * 2./3. * 0.833 ; 0.833
			val  = cwp * cph_w
			bad  = (cwp eq -999.) or (cph_w eq 0) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CLWP'] = data
		endif

		;'CIWP':
		if total(proc_list eq 'CIWP') then begin
			; heymsfield
			; val  = cph_i * (((cod>0) ^ (1./0.84))/0.065)
			val  = cwp * cph_i
			bad  = (cwp eq -999.) or (cph_i eq 0) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CIWP'] = data
		endif

		;'CIWPH':
		if total(proc_list eq 'CIWPH') then begin
			; val = cph_i * (((cod>0) ^ (1./0.84))/0.065) * ctp_h
			val  = cwp * cph_i * ctp_h
			bad  = (cwp eq -999.) or (cph_i eq 0) or (ctp_h eq 0) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CIWPH'] = data
		endif

		;'CREW':
		if total(proc_list eq 'CREW') then begin
			val  = cph_w * ref
			bad  = (ref eq -999.) OR (cph_w EQ 0) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING 
			out['CREW'] = data
		endif

		;'CREI':
		if total(proc_list eq 'CREI') then begin
			val  = cph_i * ref
			; stapel changed from cph_w to cph_i
			; bad = (ref eq -999.) OR (cph_w EQ 0)
			bad  = (ref eq -999.) OR (cph_i EQ 0) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CREI'] = data
		endif

		;'CREIH':
		if total(proc_list eq 'CREIH') then begin
			val  = cph_i * ref * ctp_h
			bad  = (ref eq -999.) OR (cph_i EQ 0) OR (ctp_h EQ 0) or ( illum ne 1 )
			good = bad eq 0
			data = val * good  + bad * MISSING
			out['CREIH'] = data
		endif
	endif

	undefine,val
	undefine,good
	undefine,bad
	undefine,data
	undefine,ctp
	undefine,ctp_l
	undefine,ctp_m
	undefine,ctp_h
	undefine,cph
	undefine,cph_w
	undefine,cph_i
	undefine,cod
	undefine,cem
	undefine,ref
	undefine,ca
	undefine,ct
	undefine,cwp
	undefine,cth

	return,out

END
