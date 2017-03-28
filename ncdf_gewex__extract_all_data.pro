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
	day_prd  = self.process_day_prds or self.process_day_prds_only

	if day_prd eq 0 then variables = ['ctp','cph','cth','cee','ctt','cmask']
	if self.process_day_prds_only then variables = ['ctp','cot','cer','cph','cmask','cwp','illum']

	nlon = long(360./self.resolution)
	nlat = long(180./self.resolution)
	MISSING = self.missing_value[0] 

	out  = orderedhash()

	l2b_data = read_level2b_data(file, node = node, variables = variables)
	ca  = l2b_data.ca
	ctp = l2b_data.ctp
	cph = l2b_data.cph
	if ~self.process_day_prds_only then cth = l2b_data.cz
	if ~self.process_day_prds_only then cem = l2b_data.cem
	if ~self.process_day_prds_only then ct  = l2b_data.ct
 	if day_prd then cod   = l2b_data.cod
	if day_prd then ref   = l2b_data.ref
	if day_prd then cwp   = l2b_data.cwp
	if day_prd then illum = l2b_data.illum

	; height levels as mask
	ctp_l = between(ctp,680,1050)
	ctp_m = between(ctp,440,680,/not_include_upper)
	ctp_h = between(ctp,000,440,/not_include_upper)

	; phase as mask (water and ice)
	; stapel cci cph has 0,1,2 := clear,liquid,ice
	cph_w = cph eq 1
	cph_i = cph eq 2

	if not self.process_day_prds_only then begin

		; 'CA'
		val  = ca ge 0.5
		bad  = ca eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CA'] = data

		; 'CAH'
		val  = (ca ge 0.5) * ctp_h
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAH'] = data

		; 'CAM'
		val  = (ca ge 0.5) * ctp_m
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAM'] = data  

		; 'CAL'
		val  = (ca ge 0.5) * ctp_l
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAL'] = data

		; 'CAW'
		val  = (ca ge 0.5) * cph_w
		bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAW'] = data

		; 'CAI'
		val  = (ca ge 0.5) * cph_i
		bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAI'] = data

		; 'CAIH'
		val  = (ca ge 0.5) * cph_i * ctp_h
		bad  = (ca eq -999.) OR ((ctp EQ -999.) AND ( ca ge 0.5)) or ((cph EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAIH'] = data

		;'CT':
		val  = ct
		bad  = ct eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CT'] = data

		;'CTH':
		val  = ct  * ctp_h
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTH'] = data

		;'CTM':
		val  = ct  * ctp_m
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CTM'] = data

		;'CTL':
		val  = ct  * ctp_l
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTL'] = data

		;'CTW':
		val  = ct * cph_w
		bad  = val le 0. 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTW'] = data

		;'CTI':
		val  = ct * cph_i
		bad  = val le 0. 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTI'] = data

		;'CTIH':
		val  = ct * cph_i * ctp_h
		bad  = val le 0.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CTIH'] = data

		;'CP':
		val  = ctp
		bad  = val eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CP'] = data

		;'CZ':
		val  = cth
		bad  = val eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CZ'] = data

		;'CEM':
		val  = cem
		bad  = cem eq -999.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEM'] = data

		;'CEMH':
		val  = cem * ctp_h
		bad  = (cem eq -999.) or (ctp_h eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMH'] = data

		;'CEMM':
		val  = cem * ctp_m
		bad  = (cem eq -999.) or (ctp_m eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMM'] = data

		;'CEML':
		val  = cem * ctp_l
		bad  = (cem eq -999.) or (ctp_l eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEML'] = data

		;'CEMW':
		val  = cem * cph_w
		bad  = (cem eq -999.) or (cph_w eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CEMW'] = data

		;'CEMI':
		val  = cem * cph_i
		bad  = (cem eq -999.) or (cph_i eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMI'] = data

		;'CEMIH':
		val  = cem * cph_i * ctp_h
		bad  = (cem eq -999.) or (cph_i eq 0) or (ctp_h eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CEMIH'] = data

		; 'CAE'
		val  = cem
		bad  = (cem eq -999.) or (ca EQ -999.)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAE'] = data

		; 'CAEH'
		val  = cem * ctp_h
		bad  = (cem eq -999.) or (ca EQ -999.)  OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEH'] = data

		; 'CAEM'
		val  = cem * ctp_m
		bad  = (cem eq -999.) or (ca EQ -999.)  OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEM'] = data

		; 'CAEL'
		val  = cem * ctp_l
		bad  = (cem eq -999.) or (ca EQ -999.)  OR ((ctp EQ -999.) AND ( ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEL'] = data

		; 'CAEW'
		val  =  cem  * cph_w
		bad  = (cem eq -999.) or (ca eq -999.) OR ((cph eq -999.) and (ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEW'] = data

		; 'CAEI'
		val  = (cem > 0.) * cph_i
		bad  = (cem eq -999.) or (ca eq -999.) OR  ((cph eq -999.) and (ca ge 0.5))
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEI'] = data

		; 'CAEIH'
		val  = (cem > 0.) * cph_i * ctp_l
		bad  = (cem eq -999.) or (ca eq -999.) OR  ((cph eq -999.) and (ca ge 0.5)) OR ((ctp EQ -999.) AND ( ca ge 0.5)) 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAEIH'] = data
	endif

	; daytime products
 	if day_prd then begin
		; 'CAD'
		val  = ca ge 0.5
		bad  = (ca eq -999.) or ( illum ne 1 )
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CAD'] = data

		; 'CAWD'
		val  = (ca ge 0.5) * cph_w
		bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5))  or ( illum ne 1 )
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CAWD'] = data

		; 'CAID'
		val  = (ca ge 0.5) * cph_i
		bad  = (ca eq -999.) OR ((cph EQ -999.) AND ( ca ge 0.5)) or ( illum ne 1) 
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CAID'] = data

		;'COD': logarithmic space
		val  = cod
		bad  = val le 0. ; STAPEL 11/2013 no cod =0 allowed, because of alog
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['COD'] = data

		;'CODH':
		val  = cod * ctp_h
		bad  = val le 0.
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CODH'] = data

		;'CODM':
		val  = cod * ctp_m
		bad  = val le 0.
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CODM'] = data

		;'CODL':
		val  = cod * ctp_l
		bad  = val le 0.
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CODL'] = data 

		;'CODW':
 		val  = cod * cph_w
		bad  = val le 0.
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CODW'] = data 

		;'CODI':
		val  = cod * cph_i
		bad  = val le 0.
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CODI'] = data 

		;'CODIH':
		val  = cod * cph_i * ctp_h
		bad  = val le 0.
		val  = alog(val>1e-15) + 10.
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CODIH'] = data

		;'CLWP':
; 		val  = (cod>0) * (ref>0) * cph_w * 2./3. * 0.833 ; 0.833
		val  = cwp * cph_w
		bad  = (cwp eq -999.) or (cph_w eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CLWP'] = data

		;'CIWP':
		; heymsfield
; 		val  = cph_i * (((cod>0) ^ (1./0.84))/0.065)
		val  = cwp * cph_i
		bad  = (cwp eq -999.) or (cph_i eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CIWP'] = data

		;'CIWPH':
; 		val = cph_i * (((cod>0) ^ (1./0.84))/0.065) * ctp_h
		val  = cwp * cph_i * ctp_h
		bad  = (cwp eq -999.) or (cph_i eq 0) or (ctp_h eq 0)
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CIWPH'] = data

		;'CREW':
		val  = cph_w * ref
		bad  = (ref eq -999.) OR (cph_w EQ 0)
		good = bad eq 0
		data = val * good  + bad * MISSING 
		out['CREW'] = data

		;'CREI':
		val  = cph_i * ref
		; stapel changed from cph_w to cph_i
		; bad = (ref eq -999.) OR (cph_w EQ 0)
		bad  = (ref eq -999.) OR (cph_i EQ 0)
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CREI'] = data

		;'CREIH':
		val  = cph_i * ref * ctp_h
		bad  = (ref eq -999.) OR (cph_i EQ 0) OR (ctp_h EQ 0)
		good = bad eq 0
		data = val * good  + bad * MISSING
		out['CREIH'] = data
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
