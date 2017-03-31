;-------------------------------------------------------------------------
function ncdf_gewex::get_l2b_varnames, product_list, incl_day_products = incl_day_products, found = found

	if n_elements(product_list) eq 0 then return, ['ctp','cot','cer','cph','cth','cee','ctt','cmask','cwp','illum']

	variables = strarr(1)
	iday      = keyword_set(incl_day_products)
	is_clara  = (self.algo eq 'CLARA_A2')

	foreach prd, product_list do begin
		if total(prd eq ['CAH','CAM','CAL','CAIH','CAEH','CAEM','CAEL'	,$
						 'CAEIH','CEMH','CEMM','CEML','CEMIH','CP'		,$
						 'CTH','CTM','CTL','CTIH','CODH','CODM','CODL'	,$
						 'CODIH','CIWPH','CREIH' ]) 									then variables = [variables,'ctp']
		if total(prd eq ['COD','CODH','CODM','CODL','CODW','CODI','CODIH'])	and iday	then variables = [variables,'cot']
		if total(prd eq ['CREW','CREI','CREIH' ])  							and iday	then variables = [variables,(is_clara ? 'ref':'cer')]
		if total(prd eq ['CAW','CAI','CAIH','CAEW','CAEI','CAEIH','CEMW',$
						 'CEMI','CEMIH','CTW','CTI','CTIH'				,$
						 'CODW','CODI','CODIH','CLWP','CIWP','CIWPH'	,$
						 'CREW','CREI','CREIH','CAWD','CAID' ]) 						then variables = [variables,'cph']
		if total(prd eq ['CZ' ]) 														then variables = [variables,'cth']
		if total(prd eq ['CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH',$
						 'CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH']) 			then variables = [variables,'cee']
		if total(prd eq ['CT','CTH','CTM','CTL','CTW','CTI','CTIH' ]) 					then variables = [variables,'ctt']
		if total(prd eq ['CA','CAH','CAM','CAL','CAW','CAI','CAIH','CAE',$
						 'CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH' ]) 					then variables = [variables,(is_clara ? 'cc_mask':'cmask')]
		if total(prd eq ['CLWP','CIWP','CIWPH' ])							and iday	then variables = [variables,'cwp']
		if total(prd eq ['CAD','CAWD','CAID','CLWP','CIWP','CIWPH'		,$
						 'CREW','CREI','CREIH','COD','CODH','CODM'		,$
						 'CODL','CODW','CODI','CODIH' ]) 					and iday	then variables = [variables,(is_clara ? 'sunzen':'illum')]
	endforeach

	if n_elements(variables) gt 1 then begin
		variables = variables[1:*]
	endif else begin
		found = 0
		return, variables
	endelse

	; remove equal names
	dum_idx = (sort(variables))[uniq(variables[sort(variables)])]
	found   = n_elements(dum_idx)

	return, variables[dum_idx]

end
;-------------------------------------------------------------------------
function ncdf_gewex::get_l2b_files, day = day, variable = variable	, $ ; e.g. for clara, so far only a dummy and not used
									count_file = count_file			, $	; number of files found
									recursive = recursive				; do recursive search if no file was found in the first place
																		; this might take a long time and should be avoided 

		yy   = string(self.year ,format='(i4.4)')
		mm   = string(self.month,format='(i2.2)')
		dd   = keyword_set(day) ? string(day,format='(i2.2)') : '??'

		if self.algo eq 'ESACCI' then begin
			; use cci naming convention
			filen  = yy+mm+dd+'-ESACCI-L3U_CLOUD-CLD_PRODUCTS-{'+strjoin(self.satnames,',')+'}-f'+self.version+'.nc'
			dir    = self.fullpath+yy+'/'+mm+'/'
		endif else if self.algo eq 'CLARA_A2' then begin
			varn   = keyword_set(variable) ? strupcase(variable) : strupcase(self.clara_default_var)
			filen  = varn+'in'+yy+mm+dd+'000000223{'+strjoin(self.satnames,',')+'}01GL.nc'
			dir    = self.fullpath+varn+'/{'+strjoin(self.satnames,',')+'}/'+yy+'/'
		endif else begin
			print,'Unknown Algorithm: ',self.algo
			stop
		endelse

		files     = file_search(dir+filen, count=count_file)
		if count_file eq 0 and keyword_set(recursive) then begin
			files = file_search(dir,filen, count=count_file)
		endif
		if count_file eq 0 then begin
			files = 'no_file'
			print,'no file  check file pattern ..',dir + filen
			print,'satellite ==> ',self.satnames
		endif

		return, files

end
;-------------------------------------------------------------------------
; $Id: ncdf_gewex__define.pro,v 1.3 2012/11/19 01:02:06 awalther Exp $

;+
; :Description:
;    Returns a structure of year information
;
; :Params:
;    am
;    pm
;    o_ampm
;    o_am
;    o_pm
;    o_0130
;    o_0730
;    o_1330
;    o_1930,optional
;
;
;
; :Author: awalther
;-
function ncdf_gewex::histogram_info, product

	case strlowcase(product) of
		'cod': begin
			bins = [0,0.3,1.3,3.6,9.4,23.,60.,1000.]
			cci_name= 'cot'
			long_name='Cloud Optical Depth '
			unit = '1'
		end

		'codi': begin
			bins = [0,0.3,1.3,3.6,9.4,23.,60.,1000.]
			cci_name= 'cot'
			long_name='Cloud Optical Depth Ice clouds'
			unit = '1'
		end

		'codw': begin
			bins = [0,0.3,1.3,3.6,9.4,23.,60.,1000.]
			cci_name= 'cot'
			long_name='Cloud Optical Depth Water clouds'
			unit='1'
		end
		
		'cp': begin
			bins = [0,180,310,440,560,680,800,1100]
			cci_name = 'ctp'
			long_name='Cloud Top Pressure '
			unit='hPa'
		end
		
		'cem':begin
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			cci_name = 'cee'
			long_name= 'Cloud Emissivity '
			unit = '1'
		end
		
		'cemi':begin
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			cci_name = 'cee'
			long_name= 'Cloud Emissivity Ice '
			unit='1'
		end
		
		'crew': begin
			; stapel changed bins according to ref) (see ncdf_gewex__update_product.pro) 
;			bins=[2.,4.,6.,10.,12.5,15,17.5,20,25,30.]
			bins=[2.,4.,6.,8.,10.,12.5,15,17.5,20,25,30.]
			cci_name = 'cer'
			long_name = 'Cloud Effective Radius Water Clouds' 
			unit='um'
		end
		
		'crei': begin
			; stapel changed bins according to ref) (see ncdf_gewex__update_product.pro) 
;	 		bins=[5.,10.,20.,40.,60.,80.,100.,150.,300.,1000.]
			bins= [0,5,10,15,20,25,30,35,40,45,50,55,60,90]
			cci_name = 'cer'
			long_name = 'Cloud Effective Radius Ice Clouds'
			unit='um'
		end

	endcase

	return,{  bins : bins		$
		, cci_name:cci_name	$
		, long_name : long_name $
		, unit : unit		$
		}

end


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


PRO ncdf_gewex::update_year

	; defines valid sensors for each year
	;                                                                              PM-N,AM-D,PM-D,AM-N
	; list : morning satellite, afternoon satellite , ampm_flag, am_flag, pm_flag, 0130,0730,1330,1930
	self.year_info = PTR_NEW(define_year_info('nnn','nnn',0B,0B,0B,0B,0B,0B,0B))
	if keyword_set(self.modis) then begin
		CASE self.year OF
			2000	: self.year_info = PTR_NEW(define_year_info ((self.month le 2 ? 'nnn':'terra'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			2001	: self.year_info = PTR_NEW(define_year_info ('terra','nnn',0B,1B,0B,0B,1B,0B,1B))
			2002	: self.year_info = PTR_NEW(define_year_info ('terra',(self.month le  6 ? 'nnn':'aqua'),1B,1B,1B,1B,1B,1B,1B))
			else	: if self.year gt 2002 then self.year_info = PTR_NEW(define_year_info('terra','aqua',1B,1B,1B,1B,1B,1B,1B))
		endcase
	endif else if keyword_set(self.famec) or keyword_set(self.aatsr) then begin
		CASE self.year OF
			2002	: self.year_info = PTR_NEW(define_year_info ((self.month le 4 ? 'nnn':'envisat'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			2012	: self.year_info = PTR_NEW(define_year_info ((self.month le 3 ? 'envisat':'nnn'),'nnn',0B,1B,0B,0B,1B,0B,1B))
			else	: if between(self.year,2003,2011) then self.year_info = PTR_NEW(define_year_info ('envisat','nnn',0B,1B,0B,0B,1B,0B,1B))
		endcase
		if keyword_set(self.famec) then begin
			; fame-c has no night node
			(*self.year_info).O_AM   = 0B
			(*self.year_info).O_1930 = 0B
		endif
	endif else if keyword_set(self.atsr2) then begin
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
; 			2013: self.year_info = PTR_NEW(define_year_info ((self.month le 4 ? 'ma':'mb'),'n19',1B,1B,1B,1B,1B,1B,1B))
; 			2014: self.year_info = PTR_NEW(define_year_info ('mb','n19',1B,1B,1B,1B,1B,1B,1B))
; 			2015: self.year_info = PTR_NEW(define_year_info ('mb','n19',1B,1B,1B,1B,1B,1B,1B))
; 			2016: self.year_info = PTR_NEW(define_year_info ('mb','n19',1B,1B,1B,1B,1B,1B,1B))
			2013: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B)) ; cci decision take MA instead of MB
			2014: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B)) ; cci decision take MA instead of MB
			2015: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B)) ; cci decision take MA instead of MB
			2016: self.year_info = PTR_NEW(define_year_info ('ma','n19',1B,1B,1B,1B,1B,1B,1B)) ; cci decision take MA instead of MB
		ENDCASE
	endelse
END

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

		'ampm': begin
			if keyword_set(self.modis) then begin
				self.outfile='_'+'MODIS-'+self.algo+'_TERRA-AQUA_AMPM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_AMPM_'
			endelse
			self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
		end

		'am' : begin
			satellite[1] = 'not_needed'
			if keyword_set(self.famec) then begin
				self.outfile='_'+'MERIS+AATSR-'+self.algo+'_ENVISAT_1030AMPM_'
			endif else if keyword_set(self.atsr2) then begin
				self.outfile='_'+'ATSR2-'+self.algo+'_ERS2_1030AMPM_'
			endif else if keyword_set(self.aatsr) then begin
				self.outfile='_'+'AATSR-'+self.algo+'_ENVISAT_1030AMPM_'
			endif else if keyword_set(self.modis) then begin 
				self.outfile='_'+'MODIS-'+self.algo+'_TERRA_1030AMPM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0730AMPM_'
			endelse
			self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
		end

		'pm' : begin
			satellite[0] = 'not_needed'
			if keyword_set(self.modis) then begin
				self.outfile='_'+'MODIS-'+self.algo+'_AQUA_0130AMPM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0130AMPM_'
			endelse
			self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
		end

		'1330':begin ; daylight node for the pm sats! (stapel (12/2014))
			satellite[0] = 'not_needed'
			if keyword_set(self.modis) then begin 
				self.outfile='_'+'MODIS-'+self.algo+'_AQUA_0130PM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0130PM_'
			endelse
			self -> update_node, ['asc']; for the pm sats 'asc' should always be in daylight! (stapel (12/2014))
		end

		'0130':begin ; night node for the pm sats! (stapel (12/2014))
			satellite[0] = 'not_needed'
			self.process_day_prds = 0l
			if keyword_set(self.modis) then begin 
				self.outfile='_'+'MODIS-'+self.algo+'_AQUA_0130AM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0130AM_'
			endelse
			self -> update_node, 'desc' ; for the pm sats 'desc' should always be night! (stapel (12/2014))
		end

		'0730':begin  ; daylight node for the am sats!  (stapel (12/2014))
			satellite[1] = 'not_needed'
			if keyword_set(self.famec) then begin
				self.outfile='_'+'MERIS+AATSR-'+self.algo+'_ENVISAT_1030AM_'
			endif else if keyword_set(self.atsr2) then begin
				self.outfile='_'+'ATSR2-'+self.algo+'_ERS2_1030AM_'
			endif else if keyword_set(self.aatsr) then begin
				self.outfile='_'+'AATSR-'+self.algo+'_ENVISAT_1030AM_'
			endif else if keyword_set(self.modis) then begin
				self.outfile='_'+'MODIS-'+self.algo+'_TERRA_1030AM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0730AM_'
			endelse
			self -> update_node, (satellite[0] eq 'n15' ? 'asc' : 'desc'); noaa15 is different (stapel (12/2014))
		end

		'1930':begin  ; night node for the am sats!  (stapel (12/2014))
			satellite[1] = 'not_needed'
			self.process_day_prds = 0l
			if keyword_set(self.famec) then begin
				self.outfile='_'+'MERIS+AATSR-'+self.algo+'_ENVISAT_1030PM_'
			endif else if keyword_set(self.atsr2) then begin
				self.outfile='_'+'ATSR2-'+self.algo+'_ERS2_1030PM_'
			endif else if keyword_set(self.aatsr) then begin
				self.outfile='_'+'AATSR-'+self.algo+'_ENVISAT_1030PM_'
			endif else if keyword_set(self.modis) then begin
				self.outfile='_'+'MODIS-'+self.algo+'_TERRA_1030PM_'
			endif else begin
				self.outfile='_'+'AVHRR-'+self.algo+'_NOAA_0730PM_'
			endelse
			self -> update_node, (satellite[0] eq 'n15' ? 'desc' : 'asc'); noaa15 is different (stapel (12/2014))
		end

	ENDCASE

	if keyword_set(self.famec) then begin
		self.sensor      = 'MERIS+AATSR'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = 'nnn'
	endif else if keyword_set(self.atsr2) then begin
		; Caroline check here, self.satnames needs to be the same as in the l3u filenames
		self.sensor      = 'ATSR2'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = 'nnn'
	endif else if keyword_set(self.aatsr) then begin
		self.sensor      = 'AATSR'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = 'nnn'
	endif else if keyword_set(self.modis) then begin
		self.sensor      = 'MODIS'
		self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(satellite[0])
		self.satnames[1] = strupcase(self.sensor)+'_'+strupcase(satellite[1])
	endif else begin
		self.sensor      = 'AVHRR'
		no_idx = where(strmid(satellite,0,1) eq 'n' and satellite ne 'nnn' and satellite ne 'not_needed',no_cnt)
		me_idx = where(strmid(satellite,0,1) eq 'm' and satellite ne 'nnn' and satellite ne 'not_needed',me_cnt)
		dum_sat = satellite
		if self.algo eq 'ESACCI' then begin
			if no_cnt gt 0 then dum_sat[no_idx] = 'noaa-'+strmid(satellite[no_idx],1)
			if me_cnt gt 0 then dum_sat[me_idx] = 'metop'+strmid(satellite[me_idx],1)
			self.satnames[0] = strupcase(self.sensor)+'_'+strupcase(dum_sat[0])
			self.satnames[1] = strupcase(self.sensor)+'_'+strupcase(dum_sat[1])
		endif else if self.algo eq 'CLARA_A2' then begin
			if no_cnt gt 0 then dum_sat[no_idx] = 'avn' +strmid(satellite[no_idx],1)
			if me_cnt gt 0 then dum_sat[me_idx] = 'avme'+strmid(satellite[me_idx],1)
			self.satnames[0] = strupcase(dum_sat[0])
			self.satnames[1] = strupcase(dum_sat[1])
		endif else begin
			print,'Unknown Algorithm', self.algo
			stop
		endelse
		satellite = dum_sat
	endelse

	idx = where(satellite eq 'nnn' or satellite eq 'not_needed',idxcnt)
	if idxcnt gt 0 then self.satnames[idx] = 'nnn'

	idx = where(self.satnames ne 'nnn',cnt)
	if cnt gt 0 then satellite = satellite[idx]
	self.platform = strcompress(strjoin(strupcase(satellite),','),/rem)

	self.full_nc_file = self.outpath+'/' $
			+string(self.year,format='(i4.4)') +'/' $
					+self.product $
					+self.outfile $
					+string(self.year,format='(i4.4)') $
					+'.nc'

	file_mkdir,file_dirname(self.full_nc_file)

END

PRO ncdf_gewex::set_product,product,current = current
	current = self.product
	self.product = product
	self->update
END

PRO ncdf_gewex::set_kind, kind
	self.kind = kind
END

PRO ncdf_gewex::set_key_ge
	self.key_ge = self.product+self.region+self.which_file
END

PRO ncdf_gewex::set_year,year
	self.year = year
	self->update
END

PRO ncdf_gewex::set_month,month
	self.month = month
	self->update
END


FUNCTION ncdf_gewex::init ,algo = algo, modis = modis, aatsr = aatsr, atsr2 = atsr2, famec = famec

	; ncdf global attributes
	self.climatology		= 'ESA Cloud_cci'
	self.contact    		= 'contact.cloudcci@dwd.de'
	self.institution		= 'Deutscher Wetterdienst'
	; ---
	self.algo       		= keyword_set(algo) ? strupcase(algo) : 'ESACCI'; string used in output filename and file_search() !!
	self.version    		= 'v2.0'  ; used in global attributes and file_search() !!
	; set dummies and defaults
	self.year       		= 2008L
	self.month      		= 1
	self.product    		= 'CA'
	self.which_file 		= 'ampm'
	self.kind       		= 'mean'
	self.nodes      		= ptr_new(['asc','desc'])
	self.missing_value 		= -999.
	self.calc_spatial_stdd	= !FALSE ; set this to !TRUE to calculate spatial stdd. for each variable instead of temporal (default)
	self.compress   		= 4 ; compress level for ncdf4 files [0-9]
	self.resolution 		= 1. ; output resolution in degree (equal angle)
	self.file 				= PTR_NEW('no_file')
	self.clara_default_var	= 'CAA'
	; ---
	; don't change this!!
	self.which_file_list 	= ['ampm','am','pm','0130','0730','1330','1930']
	; ---

	self.famec = keyword_set(famec)
	self.modis = keyword_set(modis)
	self.aatsr = keyword_set(aatsr)
	self.atsr2 = keyword_set(atsr2)

	; paths, edit here!
	apx_dir = ''
	if self.modis then apx_dir = 'MODIS/'
	if self.famec then apx_dir = 'FAMEC/'
	if self.aatsr then apx_dir = 'AATSR/'
	if self.atsr2 then apx_dir = 'ATSR2/'
	if self.algo eq 'CLARA_A2' then self.inpath = '/cmsaf/cmsaf-cld7/AVHRR_GAC_2/LEVEL2B/' else $
	if self.algo eq 'ESACCI'   then self.inpath = '/cmsaf/cmsaf-cld7/esa_cloud_cci/data/v2.0/L3U/' else begin
		print,'Algorithm not defined ',self.algo
		stop
	endelse
	self.outpath = '/cmsaf/cmsaf-cld8/sstapelb/gewex/test_gac_cci/'+apx_dir
	; ---

	; here you find all the defined variable names
	; you can choose which of the variables you want to process
	; Note! New variables need to be defined e.g. in "extract_all_data" and elsewhere
	self.all_prd_list	= PTR_NEW([	'CA','CAH','CAM','CAL','CAW','CAI','CAIH'			, $
; 									'CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH'	, $
; 									'CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH'	, $
									'CP','CZ','CT','CTH','CTM','CTL','CTW','CTI','CTIH'	, $
									'COD','CODH','CODM','CODL','CODW','CODI','CODIH'	, $ ; day only
; 									'ALWP','AIWP','AIWPH'								, $ ; day only, won't work; not defined yet
									'CLWP','CIWP','CIWPH','CREW','CREI','CREIH'			, $ ; day only
									'CAD','CAWD','CAID']) 									; day only
	self.rel_prd_list 	= PTR_NEW([	'CAHR','CAMR','CALR','CAWR','CAIR','CAIHR','CAWDR','CAIDR'])
	self.hist_prd_list	= PTR_NEW([	'COD_CP','CEM_CP','CEMI_CREI','CODW_CREW','CODI_CREI'])
	;--------------------------------------------------------------------------------------------------

	self -> update

	return,1
end


PRO  ncdf_gewex__define

   void = { ncdf_gewex $
	  , inherits idl_object $
	  , year : 1980L $
	  , month : 11L $
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
	  , platform : '' $
	  , which_file_list : strarr(7) $
	  , algo : '' $ 
	  , version : '' $ 
	  , climatology : '' $ 
	  , contact : '' $ 
	  , institution : '' $ 
	  , kind : '' $
	  , missing_value : 0. $
	  , compress : 0l $
	  , process_day_prds : 1l $
	  , modis : 0l $
	  , aatsr : 0l $
	  , atsr2 : 0l $
	  , famec : 0l $
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