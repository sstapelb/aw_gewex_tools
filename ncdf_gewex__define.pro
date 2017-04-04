;+
; :Description:
;    Creates hash of varnames as used in the l2b file (varies on algoritms),
;    depending on which Gewex products shall be processed.
;
; :Purpose:
;    the hash will be used in read_l2b_data
;
;
; :Keywords:
;    product_list
;
;
;
; :Author: sstapelberg
;-
;-------------------------------------------------------------------------
function ncdf_gewex::get_l2b_varnames, product_list, found = found

	prd_list = n_elements(product_list) eq 0 ? *self.all_prd_list : product_list
	vars 	 = hash()

	foreach prd, strupcase(prd_list) do begin
		; allday products
		if total(prd eq ['CAH','CAM','CAL','CAIH','CAEH','CAEM','CAEL'	,$
						 'CAEIH','CEMH','CEMM','CEML','CEMIH','CP'		,$
						 'CTH','CTM','CTL','CTIH','CODH','CODM','CODL'	,$
						 'CODIH','CIWPH','CREIH' ]) and (vars.haskey('CTP') eq 0)	then vars['CTP'] = {var:'ctp',path:'',unit_scale:1.0}
		if total(prd eq ['CAW','CAI','CAIH','CAEW','CAEI','CAEIH','CEMW',$
						 'CEMI','CEMIH','CTW','CTI','CTIH'				,$
						 'CODW','CODI','CODIH','CLWP','CIWP','CIWPH'	,$
						 'CREW','CREI','CREIH','CAWD','CAID' ])  and $
						 (vars.haskey('CPH') eq 0)									then vars['CPH'] = {var:'cph',path:'',unit_scale:1.0}
		if total(prd eq ['CZ' ]) and (vars.haskey('CTH') eq 0)						then vars['CTH'] = {var:'cth',path:'',unit_scale:1.0}
		if total(prd eq ['CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH',$
						 'CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH']) $
						  and (vars.haskey('CEE') eq 0) 							then vars['CEE'] = {var:'cee',path:'',unit_scale:1.0}
		if total(prd eq ['CT','CTH','CTM','CTL','CTW','CTI','CTIH' ]) $
						 and  (vars.haskey('CTT') eq 0)								then vars['CTT'] = {var:'ctt',path:'',unit_scale:1.0}
		if total(prd eq ['CA','CAH','CAM','CAL','CAW','CAI','CAIH','CAE',$
						 'CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH']) $ 
						 and (vars.haskey('CMASK') eq 0) 							then vars['CMASK'] = {var:'cmask',path:'',unit_scale:1.0}
		; daytime products
		if (self.process_day_prds) then begin
			if total(prd eq ['CLWP','CIWP','CIWPH']) and (vars.haskey('CWP') eq 0) 	then vars['CWP'] = {var:'cwp',path:'',unit_scale:1.0}
			if total(prd eq ['COD','CODH','CODM','CODL','CODW','CODI','CODIH'])$
							  and (vars.haskey('COT') eq 0)							then vars['COT'] = {var:'cot',path:'',unit_scale:1.0}
			if total(prd eq ['CREW','CREI','CREIH']) and (vars.haskey('CER') eq 0)	then vars['CER'] = {var:'cer',path:'',unit_scale:1.0}
			if total(prd eq ['CAD','CAWD','CAID','CLWP','CIWP','CIWPH','CODL',$
							 'CREW','CREI','CREIH','COD','CODH','CODM','CODW',$
							 'CODI','CODIH']) and (vars.haskey('ILLUM') eq 0)		then vars['ILLUM'] = {var:'illum',path:'',unit_scale:1.0}
		endif
	endforeach

	if self.clara2 then begin
		if vars.haskey('CER')	then vars['CER']	= {var:'ref',path:'CWP',unit_scale:1000000.0}
		if vars.haskey('CMASK')	then vars['CMASK']	= {var:'cc_mask',path:'CMA',unit_scale:1.0}
		if vars.haskey('ILLUM')	then vars['ILLUM']	= {var:'sunzen',path:'CAA',unit_scale:1.0}; for clara illum will be created in read_l2b_data
		if vars.haskey('CTP')	then vars['CTP']	= {var:'ctp',path:'CTO',unit_scale:1.0}
		if vars.haskey('CTH')	then vars['CTH']	= {var:'cth',path:'CTO',unit_scale:0.001}
		if vars.haskey('CTT')	then vars['CTT']	= {var:'ctt',path:'CTO',unit_scale:1.0}
		if vars.haskey('COT')	then vars['COT']	= {var:'cot',path:'CWP',unit_scale:1.0}
		if vars.haskey('CWP')	then vars['CWP']	= {var:'cwp',path:'CWP',unit_scale:1000.0}
		if vars.haskey('CPH')	then vars['CPH']	= {var:'cph',path:'CPH',unit_scale:1.0}
		if vars.haskey('CEE')	then vars['CEE']	= {var:'',path:'',unit_scale:1.0} ; not defined in clara remove from prd_list
	endif

	found = n_elements(vars)

	return, vars

end
;-------------------------------------------------------------------------
;+
; :Description:
;    Builds L2b filenames
;
; :Keywords:
;    day 		- 	specific day if not specified all files of the months 
;    recursive 	- 	do recursive search if no file was found in the first place
; 					this might take a long time and should be avoided 
;
; :Author: sstapelberg
;-
;-------------------------------------------------------------------------
function ncdf_gewex::get_l2b_files, day = day, recursive = recursive, count = count

		yy   = string(self.year ,format='(i4.4)')
		mm   = string(self.month,format='(i2.2)')
		dd   = keyword_set(day) ? string(day,format='(i2.2)') : '??'

		if self.clara2 then begin
			varn   = strupcase(self.clara_default_var)
			grid   = '23' ; 0.05 degree regular global grid
			filen  = varn+'in'+yy+mm+dd+'0000'+self.version+grid+'{'+strjoin(self.satnames,',')+'}01GL.nc'
			dir    = self.fullpath+varn+'/{'+strjoin(self.satnames,',')+'}/'+yy+'/'
		endif else begin
			; use cci naming convention
			filen  = yy+mm+dd+'-ESACCI-L3U_CLOUD-CLD_PRODUCTS-{'+strjoin(self.satnames,',')+'}-f'+self.version+'.nc'
			dir    = self.fullpath+yy+'/'+mm+'/'
		endelse

		files     = file_search(dir+filen, count=count)
		if count eq 0 and keyword_set(recursive) then begin
			files = file_search(dir,filen, count=count)
		endif
		if count eq 0 then begin
			files = 'no_file'
			print,'no file  check file pattern ..',dir + filen
			print,'satellite ==> ',self.satnames
		endif

		return, files

end
;-------------------------------------------------------------------------
pro ncdf_gewex::exclude_from_lists, ex_prd_list

	foreach prd, strupcase(ex_prd_list) do begin
		; all products
		idx = where((*self.all_prd_list) eq prd,idxcnt,complement=no_idx,ncomplement=no_idxcnt)
		if idxcnt gt 0 and no_idxcnt gt 0 then self.all_prd_list = ptr_new((*self.all_prd_list)[no_idx])
		; rel products
		idx = where((*self.rel_prd_list) eq prd,idxcnt,complement=no_idx,ncomplement=no_idxcnt)
		if idxcnt gt 0 and no_idxcnt gt 0 then self.rel_prd_list = ptr_new((*self.rel_prd_list)[no_idx])
		; hist_products
		idx = where((*self.hist_prd_list) eq prd,idxcnt,complement=no_idx,ncomplement=no_idxcnt)
		if idxcnt gt 0 and no_idxcnt gt 0 then self.hist_prd_list = ptr_new((*self.hist_prd_list)[no_idx])
	endforeach

end
;-------------------------------------------------------------------------
FUNCTION define_year_info, am,pm,  o_ampm , o_am ,o_pm $
            , o_0130 ,o_0730 , o_1330 , o_1930 

	RETURN,{ $
		am 	: am	, $
		pm	: pm	, $
		o_ampm : o_ampm, $
		o_am 	: o_am	, $
		o_pm 	: o_pm	, $
		o_0130 : o_0130, $
		o_0730 : o_0730, $
		o_1330 : o_1330, $
		o_1930 : o_1930  $
		} 

END
;-------------------------------------------------------------------------
PRO ncdf_gewex::update_year

	; defines valid sensors for each year
	;                                                                              PM-N,AM-D,PM-D,AM-N
	; list : morning satellite, afternoon satellite , ampm_flag, am_flag, pm_flag, 0130,0730,1330,1930
	self.year_info = PTR_NEW(define_year_info('nnn','nnn',0B,0B,0B,0B,0B,0B,0B))
	if self.modis then begin
		CASE self.year OF
			2000	: self.year_info = PTR_NEW(define_year_info ((self.month le 2 ? 'nnn':'terra'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			2001	: self.year_info = PTR_NEW(define_year_info ('terra','nnn',0B,1B,0B,0B,1B,0B,1B))
			2002	: self.year_info = PTR_NEW(define_year_info ('terra',(self.month le  6 ? 'nnn':'aqua'),1B,1B,1B,1B,1B,1B,1B))
			else	: if self.year gt 2002 then self.year_info = PTR_NEW(define_year_info('terra','aqua',1B,1B,1B,1B,1B,1B,1B))
		endcase
	endif else if (self.famec or self.aatsr) then begin
		CASE self.year OF
			2002	: self.year_info = PTR_NEW(define_year_info ((self.month le 4 ? 'nnn':'envisat'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			2012	: self.year_info = PTR_NEW(define_year_info ((self.month le 3 ? 'envisat':'nnn'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			else	: if between(self.year,2003,2011) then self.year_info = PTR_NEW(define_year_info ('envisat','nnn',0B,1B,0B,0B,1B,0B,1B))
		endcase
		if self.famec then begin
			; fame-c has no night node
			(*self.year_info).O_AM   = 0B
			(*self.year_info).O_1930 = 0B
		endif
	endif else if self.atsr2 then begin
		CASE self.year OF
			1995	: self.year_info = PTR_NEW(define_year_info ((self.month le 7 ? 'nnn':'ers2'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			else	: if between(self.year,1996,2002) then self.year_info = PTR_NEW(define_year_info ('ers2','nnn',0B,1B,0B,0B,1B,0B,1B))
		endcase
	endif else begin
		;AVHRR
		CASE self.year OF
			1981: self.year_info = PTR_NEW(define_year_info ('nnn',(self.month le  7 ? 'nnn':'n7'),0B,0B,1B,1B,0B,1B,0B))
			1982: self.year_info = PTR_NEW(define_year_info ('nnn','n7',0B,0B,1B,1B,0B,1B,0B))
			1983: self.year_info = PTR_NEW(define_year_info ('nnn','n7',0B,0B,1B,1B,0B,1B,0B))
			1984: self.year_info = PTR_NEW(define_year_info ('nnn','n7',0B,0B,1B,1B,0B,1B,0B))
			1985: self.year_info = PTR_NEW(define_year_info ('nnn',(self.month le  1 ? 'n7':'n9'),0B,0B,1B,1B,0B,1B,0B))
			1986: self.year_info = PTR_NEW(define_year_info ('nnn','n9',0B,0B,1B,1B,0B,1B,0B))
			1987: self.year_info = PTR_NEW(define_year_info ('nnn','n9',0B,0B,1B,1B,0B,1B,0B))
			1988: self.year_info = PTR_NEW(define_year_info ('nnn',(self.month le 10 ? 'n9':'n11'),0B,0B,1B,1B,0B,1B,0B))
			1989: self.year_info = PTR_NEW(define_year_info ('nnn','n11',0B,0B,1B,1B,0B,1B,0B))
			1990: self.year_info = PTR_NEW(define_year_info ('nnn','n11',0B,0B,1B,1B,0B,1B,0B))
			1991: self.year_info = PTR_NEW(define_year_info ((self.month le  9 ? 'nnn':'n12'),'n11',1B,1B,1B,1B,1B,1B,1B))
			1992: self.year_info = PTR_NEW(define_year_info ('n12','n11',1B,1B,1B,1B,1B,1B,1B))
			1993: self.year_info = PTR_NEW(define_year_info ('n12','n11',1B,1B,1B,1B,1B,1B,1B))
			1994: self.year_info = PTR_NEW(define_year_info ('n12',(self.month le  9 ? 'n11':'nnn'),1B,1B,1B,1B,1B,1B,1B))
			1995: self.year_info = PTR_NEW(define_year_info ('n12',(self.month le  1 ? 'nnn':'n14'),1B,1B,1B,1B,1B,1B,1B))
			1996: self.year_info = PTR_NEW(define_year_info ('n12','n14',1B,1B,1B,1B,1B,1B,1B))
			1997: self.year_info = PTR_NEW(define_year_info ('n12','n14',1B,1B,1B,1B,1B,1B,1B))
			1998: self.year_info = PTR_NEW(define_year_info ('n12','n14',1B,1B,1B,1B,1B,1B,1B))  ; 15 die letzten tage
			1999: self.year_info = PTR_NEW(define_year_info ('n15','n14',1B,1B,1B,1B,1B,1B,1B))  ; 14 only odd days
			2000: self.year_info = PTR_NEW(define_year_info ('n15','n14',1B,1B,1B,1B,1B,1B,1B))
			2001: self.year_info = PTR_NEW(define_year_info ('n15',(self.month le  3 ? 'n14':'n16'),1B,1B,1B,1B,1B,1B,1B))
			2002: self.year_info = PTR_NEW(define_year_info ((self.month le 10 ? 'n15':'n17'),'n16',1B,1B,1B,1B,1B,1B,1B))
			2003: self.year_info = PTR_NEW(define_year_info ('n17','n16',1B,1B,1B,1B,1B,1B,1B))
			2004: self.year_info = PTR_NEW(define_year_info ('n17','n16',1B,1B,1B,1B,1B,1B,1B))
			2005: self.year_info = PTR_NEW(define_year_info ('n17',(self.month le  8 ? 'n16':'n18'),1B,1B,1B,1B,1B,1B,1B))
			2006: self.year_info = PTR_NEW(define_year_info ('n17','n18',1B,1B,1B,1B,1B,1B,1B))
			2007: self.year_info = PTR_NEW(define_year_info ((self.month le  6 ? 'n17':'ma'),'n18',1B,1B,1B,1B,1B,1B,1B))
			2008: self.year_info = PTR_NEW(define_year_info ('ma','n18',1B,1B,1B,1B,1B,1B,1B))
			2009: self.year_info = PTR_NEW(define_year_info ('ma',(self.month le  5 ? 'n18':'n19'),1B,1B,1B,1B,1B,1B,1B)) ; launch noaa19 Feb/2009 
			2010: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B))
			2011: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B))
			2012: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B))
			2013: self.year_info = PTR_NEW(define_year_info ((self.month le 4 ? 'ma':(self.clara2 ? 'mb':'ma')),'n19',1B,1B,1B,1B,1B,1B,1B))
			2014: self.year_info = PTR_NEW(define_year_info ((self.clara2 ? 'mb':'ma'),'n19',1B,1B,1B,1B,1B,1B,1B))
			2015: self.year_info = PTR_NEW(define_year_info ((self.clara2 ? 'mb':'ma'),'n19',1B,1B,1B,1B,1B,1B,1B))
			2016: self.year_info = PTR_NEW(define_year_info ((self.clara2 ? 'mb':'ma'),'n19',1B,1B,1B,1B,1B,1B,1B))
		ENDCASE
	endelse
END
;-------------------------------------------------------------------------
; stapel (12/2014)
PRO ncdf_gewex::update_node, nodes
	self.nodes = ptr_new(nodes)
end

;+
; :Description:
;    Describe the procedure.
;
; :Params:
;    which
;
;
;
; :Author: awalther
;-
PRO ncdf_gewex::set_which, which
	self.which_file=strlowcase(which)
	self.update
END
;----------------------------------------------
;
;

;+
; :Description:
;    Describe the procedure.
;
;
;
; :Keywords:
;    year
;    month
;    file
;    count_file
;    inpath
;    full_path
;    outpath
;    which_file
;    satellite
;
; :Author: awalther
;-
PRO ncdf_gewex::getProperty $
		, year = year $
		, inpath = inpath
		year = self.year
		inpath = self.inpath
END
;-------------------------------------------------------------------------
;+
; :Description:
;    Describe the procedure.
;
;
;
;
;
; :Author: awalther
;-
PRO ncdf_gewex::update

	self-> update_year
	self-> update_product
	; stapel (12/2014) introduced self->update_nodes 
	; Here is my interpretation:
	; e.g., in 2007-2009
	; NOAA15 is the prime Morning   Satellite ('0730': node = 'desc' (daylight), '1930': node = 'asc'  (night) , 'am': node = ['asc','desc'])
	; NOAA18 is the prime Afternoon Satellite ('1330': node = 'asc'  (daylight), '0130': node = 'desc' (night) , 'pm': node = ['asc','desc'])
	; which = 'ampm' will do Noaa15 and Noaa18 for 'asc' and 'desc' 
	; -------------------------------------------------------------

	self.fullpath = self.inpath +'/'

	satellite = [(*self.year_info).am,(*self.year_info).pm]

	self.process_day_prds = 1l

	CASE strLowCase(self.which_file) of

		'ampm':	begin
					if self.modis then 	self.outfile='_'+'MODIS-'+self.algo+'_TERRA-AQUA_AMPM_'	else $
										self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_AMPM_'

					self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
				end
		'am' : 	begin
					satellite[1] = 'not_needed'
					if self.famec then 	self.outfile='_'+'MERIS+AATSR-'	+self.algo+'_ENVISAT_1030AMPM_'	else $
					if self.atsr2 then 	self.outfile='_'+'ATSR2-'		+self.algo+'_ERS2_1030AMPM_'	else $
					if self.aatsr then 	self.outfile='_'+'AATSR-'		+self.algo+'_ENVISAT_1030AMPM_'	else $
					if self.modis then 	self.outfile='_'+'MODIS-'		+self.algo+'_TERRA_1030AMPM_'	else $
										self.outfile='_'+'AVHRR-'		+self.algo+'_NOAA_0730AMPM_'
			
					self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
				end
		'pm' : 	begin
					satellite[0] = 'not_needed'
					if self.modis then 	self.outfile='_'+'MODIS-'+self.algo+'_AQUA_0130AMPM_'	else $
										self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0130AMPM_'

					self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
				end
		'1330':	begin ; daylight node for the pm sats! (stapel (12/2014))
					satellite[0] = 'not_needed'
					if self.modis then	self.outfile='_'+'MODIS-'+self.algo+'_AQUA_0130PM_'	else $
										self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0130PM_'

					self -> update_node, 'asc' ; for the pm sats 'asc' should always be in daylight! (stapel (12/2014))
				end
		'0130':	begin ; night node for the pm sats! (stapel (12/2014))
					satellite[0] = 'not_needed'
					self.process_day_prds = 0l
					if self.modis then	self.outfile='_'+'MODIS-'+self.algo+'_AQUA_0130AM_'	else $
										self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0130AM_'

					self -> update_node, 'desc' ; for the pm sats 'desc' should always be night! (stapel (12/2014))
				end
		'0730':	begin  ; daylight node for the am sats!  (stapel (12/2014))
					satellite[1] = 'not_needed'
					if self.famec then	self.outfile='_'+'MERIS+AATSR-'	+self.algo+'_ENVISAT_1030AM_'	else $
					if self.atsr2 then 	self.outfile='_'+'ATSR2-'		+self.algo+'_ERS2_1030AM_'		else $
					if self.aatsr then 	self.outfile='_'+'AATSR-'		+self.algo+'_ENVISAT_1030AM_'	else $
					if self.modis then 	self.outfile='_'+'MODIS-'		+self.algo+'_TERRA_1030AM_'		else $
										self.outfile='_'+'AVHRR-'		+self.algo+'_NOAA_0730AM_'

					self -> update_node, 'desc' ; for the pm sats 'desc' should always be daylight! (stapel (12/2014))
				end
		'1930':	begin  ; night node for the am sats!  (stapel (12/2014))
					satellite[1] = 'not_needed'
					self.process_day_prds = 0l
					if self.famec then	self.outfile='_'+'MERIS+AATSR-'	+self.algo+'_ENVISAT_1030PM_'	else $
					if self.atsr2 then	self.outfile='_'+'ATSR2-'		+self.algo+'_ERS2_1030PM_'		else $
					if self.aatsr then	self.outfile='_'+'AATSR-'		+self.algo+'_ENVISAT_1030PM_'	else $
					if self.modis then	self.outfile='_'+'MODIS-'		+self.algo+'_TERRA_1030PM_'		else $
										self.outfile='_'+'AVHRR-'		+self.algo+'_NOAA_0730PM_'

					self -> update_node, 'asc' ; for the pm sats 'asc' should always be night! (stapel (12/2014))
				end

	ENDCASE

	; satnames will be used in file_search, make sure its the same as in the l2b filenames!
	if self.famec then begin
		self.sensor      = 'MERIS+AATSR'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = 'nnn'
	endif else if self.atsr2 then begin
		self.sensor      = 'ATSR2'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = 'nnn'
	endif else if self.aatsr then begin
		self.sensor      = 'AATSR'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = 'nnn'
	endif else if self.modis then begin
		self.sensor      = 'MODIS'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = strupcase(self.sensor)+'_'+strupcase(satellite[1])
	endif else if self.clara2 then begin
		self.sensor      = 'AVHRR'
		no_idx = where(strmid(satellite,0,1) eq 'n' and satellite ne 'nnn' and satellite ne 'not_needed',no_cnt)
		me_idx = where(strmid(satellite,0,1) eq 'm' and satellite ne 'nnn' and satellite ne 'not_needed',me_cnt)
		dum_sat = satellite
		if no_cnt gt 0 then dum_sat[no_idx] = 'avn' +string(strmid(satellite[no_idx],1),format='(i2.2)')
		if me_cnt gt 0 then dum_sat[me_idx] = 'avme'+strmid(satellite[me_idx],1)
		self.satnames[0] = strupcase(dum_sat[0])
		self.satnames[1] = strupcase(dum_sat[1])
		satellite = dum_sat
	endif else begin ; default ESACCI AVHRR
		self.sensor      = 'AVHRR'
		no_idx = where(strmid(satellite,0,1) eq 'n' and satellite ne 'nnn' and satellite ne 'not_needed',no_cnt)
		me_idx = where(strmid(satellite,0,1) eq 'm' and satellite ne 'nnn' and satellite ne 'not_needed',me_cnt)
		dum_sat = satellite
		if no_cnt gt 0 then dum_sat[no_idx] = 'noaa-'+strmid(satellite[no_idx],1)
		if me_cnt gt 0 then dum_sat[me_idx] = 'metop'+strmid(satellite[me_idx],1)
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(dum_sat[0])
		self.satnames[1] = strupcase(self.sensor)+'_'+strupcase(dum_sat[1])
		satellite = dum_sat
	endelse

	idx = where(satellite eq 'nnn' or satellite eq 'not_needed',idxcnt)
	if idxcnt gt 0 then self.satnames[idx] = 'nnn'

	idx = where(self.satnames ne 'nnn',cnt)
	if cnt gt 0 then satellite = satellite[idx]
	self.platform = strcompress(strjoin(strupcase(satellite),','),/rem)

	self.variables = ptr_new(self -> get_l2b_varnames())

	self.full_nc_file = self.outpath+'/' $
						+string(self.year,format='(i4.4)') +'/' $
						+self.product $
						+self.outfile $
						+string(self.year,format='(i4.4)') $
						+'.nc'

	file_mkdir,file_dirname(self.full_nc_file)

END
;-------------------------------------------------------------------------
PRO ncdf_gewex::set_product,product,current = current
	current = self.product
	self.product = product
	self->update
END
;-------------------------------------------------------------------------
PRO ncdf_gewex::set_kind, kind
	self.kind = kind
END
;-------------------------------------------------------------------------
PRO ncdf_gewex::set_key_ge
	self.key_ge = self.product+self.region+self.which_file
END
;-------------------------------------------------------------------------
PRO ncdf_gewex::set_year,year
	self.year = year
	self->update
END
;-------------------------------------------------------------------------
PRO ncdf_gewex::set_month,month
	self.month = month
	self->update
END
;-------------------------------------------------------------------------
FUNCTION ncdf_gewex::init, modis = modis, aatsr = aatsr, atsr2 = atsr2, famec = famec, clara2 = clara2

	self.famec  = keyword_set(famec)
	self.modis  = keyword_set(modis)
	self.aatsr  = keyword_set(aatsr)
	self.atsr2  = keyword_set(atsr2)
	self.clara2 = keyword_set(clara2)

	; set dummies for startup
	self.year       		= 2008L
	self.month      		= 1
	self.product    		= 'CA'
	self.which_file 		= 'ampm'
	self.nodes      		= ptr_new(['asc','desc'])
	self.variables			= ptr_new('cmask')
	self.file 				= PTR_NEW('no_file')
	; ---
	; ncdf global attributes
	self.climatology		= self.clara2 ? 'CLARA-A2' : 'ESA Cloud_cci'
	self.contact    		= self.clara2 ? 'contact.cmsaf@dwd.de' : 'contact.cloudcci@dwd.de'
	self.institution		= 'Deutscher Wetterdienst'
	; ---
	self.algo       		= self.clara2 ? 'CLARA_A2' : 'ESACCI'	; string used in output filename
	self.version    		= self.clara2 ? '002' : 'v2.0'  		; used in global attributes and file_search() !!
	self.missing_value 		= -999.									; Fillvalue used in output ncdfs
	self.calc_spatial_stdd	= 0										; calculate spatial instead of temporal stdd. (default)
	self.compress   		= 4 									; compress level for ncdf4 files [0-9]
	self.resolution 		= 1. 									; output resolution in degree (equal angle)
	self.clara_default_var	= 'CAA'									; this is the path where the l2b files of clara will be searched
	; ---
	; don't change this!!
	self.which_file_list 	= ['ampm','am','pm','0130','0730','1330','1930']
	; ---

	; paths, edit here!
	apx_dir = 'AVHRR/'
	if self.modis  then apx_dir = 'MODIS/'
	if self.famec  then apx_dir = 'FAMEC/'
	if self.aatsr  then apx_dir = 'AATSR/'
	if self.atsr2  then apx_dir = 'ATSR2/'
	if self.clara2 then self.inpath = '/cmsaf/cmsaf-cld7/AVHRR_GAC_2/LEVEL2B/' $
	else self.inpath = '/cmsaf/cmsaf-cld7/esa_cloud_cci/data/v2.0/L3U/'
	self.outpath = '/cmsaf/cmsaf-cld7/esa_cloud_cci/data/v2.0/gewex/new/'+apx_dir
	; ---

	; !Dont change anything here. Use below procedure "remove_from_lists" to remove products!
	; Here you find all the defined variables that will be processed. Optical properties will 
	; only processed if daylight node is involved!
	; New variables need to be defined e.g. in "extract_all_data" and elsewhere
	; 'ALWP','AIWP','AIWPH' not included yet
	self.all_prd_list	= PTR_NEW([	'CA','CAH','CAM','CAL','CAW','CAI','CAIH'			, $
									'CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH'	, $
									'CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH'	, $
									'CP','CZ','CT','CTH','CTM','CTL','CTW','CTI','CTIH'	, $
									'COD','CODH','CODM','CODL','CODW','CODI','CODIH'	, $ ; day only
									'CLWP','CIWP','CIWPH','CREW','CREI','CREIH'			, $ ; day only
									'CAD','CAWD','CAID']) 									; day only
	self.rel_prd_list 	= PTR_NEW([	'CAHR','CAMR','CALR','CAWR','CAIR','CAIHR','CAWDR','CAIDR'])
	self.hist_prd_list	= PTR_NEW([	'COD_CP','CEM_CP','CEMI_CREI','CODW_CREW','CODI_CREI'])
	;--------------------------------------------------------------------------------------------------

	; Remove products from the lists, e.g. CLARA-A2 has no CEM included
	; removed products will not be processed!
	if self.clara2 then self.exclude_from_lists,[	'CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH',$
													'CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH',$
													'CEM_CP','CEMI_CREI']

	self -> update

	return,1
end
;-------------------------------------------------------------------------
PRO  ncdf_gewex__define

   void = { ncdf_gewex $
	  , inherits idl_object $
	  , year : 2000L $
	  , month : 1L $
	  , year_info : PTR_NEW()  $
	  , product : '' $
	  , product_info : PTR_NEW() $
	  , file : PTR_NEW() $
	  , count_file : 0L $
	  , inpath : '' $
	  , fullpath : '' $
	  , outpath : '' $
	  , clara_default_var : '' $
	  , nodes : ptr_new() $
	  , result_path : '' $
	  , outfile : '' $
	  , full_nc_file : '' $
	  , which_file : '' $
	  , satnames : ['',''] $
	  , variables : PTR_NEW() $
	  , platform : '' $
	  , which_file_list : strarr(7) $
	  , algo : '' $ 
	  , version : '' $ 
	  , climatology : '' $ 
	  , contact : '' $ 
	  , institution : '' $ 
	  , missing_value : 0. $
	  , compress : 0l $
	  , process_day_prds : 1l $
	  , modis : 0l $
	  , aatsr : 0l $
	  , atsr2 : 0l $
	  , famec : 0l $
	  , clara2 : 0l $
	  , sensor: '' $
	  , key_ge : '' $
	  , which : '' $
	  , calc_spatial_stdd : 0 $
	  , all_prd_list : ptr_new() $
	  , rel_prd_list : ptr_new() $
	  , hist_prd_list: ptr_new() $
	  , resolution : 1. $
        }
END
