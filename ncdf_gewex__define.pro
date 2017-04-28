;+
; :Description:
;    spawns the last commit HASH number of the git repository if available
;    
;
; :Purpose:
;    the hash will be written to the history global attribute
;
; :Keywords:
;    none
;
;
; :Author: sstapelberg
;-
;-------------------------------------------------------------------------
pro ncdf_gewex::get_git_hash

	; check if git is installed on your computer
	if file_test(file_which(getenv('PATH'),'git')) then begin
		; find parent directory of the gewex program code via traceback
		help,/traceback,output=out
		gwx_prog_path = file_dirname((reverse(strsplit(out[0],/ext)))[0])
		; if its a valid directory spawn the git command to get the latest commit hash
		if file_test(gwx_prog_path,/directory) then begin
			cd, gwx_prog_path, current = current_dir
			spawn,['git','rev-parse','HEAD'], commit_hash, ERROR, /NOSHELL
			cd, current_dir
			self.git_commit_hash = commit_hash
		endif
	endif
	stop
	;---
end
;-------------------------------------------------------------------------
;+
; :Description:
;    Creates hash of varnames as used in the l2b file (varies between algorithms),
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

	if self.use_cci_corrected_heights then begin
		if vars.haskey('CTP')	then vars['CTP']	= {var:'ctp_corrected',path:'',unit_scale:1.0}
		if vars.haskey('CTH')	then vars['CTH']	= {var:'cth_corrected',path:'',unit_scale:1.0}
		if vars.haskey('CTT')	then vars['CTT']	= {var:'ctt_corrected',path:'',unit_scale:1.0}
	endif

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

	if self.hector then begin
		if vars.haskey('CMASK')	then vars['CMASK']	= {var:'cc_mask',path:'CMA',unit_scale:1.0}
		if vars.haskey('CTP')	then vars['CTP']	= {var:'ctp',path:'CTO',unit_scale:1.0}
		if vars.haskey('CTH')	then vars['CTH']	= {var:'cth',path:'CTO',unit_scale:0.001}
		if vars.haskey('CTT')	then vars['CTT']	= {var:'ctt',path:'CTO',unit_scale:1.0}
		if vars.haskey('CEE')	then vars['CEE']	= {var:'cem',path:'CMA',unit_scale:0.01}
	endif

	if self.famec or self.meris then vars['SZA']	= {var:'solzen',path:'',unit_scale:1.0}
	if self.meris then begin
		if vars.haskey('CTP')	then vars['CTP']	= {var:'ctp2',path:'',unit_scale:1.0}
		if vars.haskey('CTH')	then vars['CTH']	= {var:'cth2',path:'',unit_scale:1.0}
		if vars.haskey('CTT')	then vars['CTT']	= {var:'ctt2',path:'',unit_scale:1.0}
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
			varn   = strupcase(self.cmsaf_path)
			grid   = '23' ; 0.05 degree regular global grid
			filen  = varn+'in'+yy+mm+dd+'0000'+self.version+grid+'{'+strjoin(self.satnames,',')+'}01GL.nc'
			dir    = self.fullpath+varn+'/{'+strjoin(self.satnames,',')+'}/'+yy+'/'
		endif else if self.hector then begin
			varn   = strupcase(self.cmsaf_path)
			grid   = '19' ; 0.25 degree regular global grid
			filen  = varn+'in'+yy+mm+dd+'0000'+self.version+grid+'{'+strjoin(self.satnames,',')+'}01GL.nc'
			dir    = self.fullpath+varn+'/{'+strjoin(self.satnames,',')+'}/'+yy+'/'
		endif else begin
			; use cci naming convention
			filen  = yy+mm+dd+'-ESACCI-L3U_CLOUD-CLD_PRODUCTS-{'+strjoin(self.satnames,',')+'}-f'+self.version+'.nc'
; 			dir    = self.fullpath+yy+'/'+mm+'/'+dd+'/' ; if you have day subdirs this will work
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
;+
; :Description:
;    Removes Products from the product lists
;
; :Keywords:
;    
; :Author: sstapelberg
;-
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
FUNCTION define_year_info, am, pm, o_ampm, o_am, o_pm, o_0130, o_0730, o_1330, o_1930 

	RETURN,{ $
		am 		: am	, $
		pm		: pm	, $
		o_ampm	: o_ampm, $
		o_am 	: o_am	, $
		o_pm 	: o_pm	, $
		o_0130	: o_0130, $
		o_0730	: o_0730, $
		o_1330	: o_1330, $
		o_1930	: o_1930  $
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
	endif else if self.hector then begin
		;HIRS
		CASE self.year OF
			1979: self.year_info = PTR_NEW(define_year_info ((self.month le  6 ? 'nnn':'HIN06'),'HIN05',1B,1B,1B,1B,1B,1B,1B))
			1980: self.year_info = PTR_NEW(define_year_info ('HIN06','HIN05',1B,1B,1B,1B,1B,1B,1B))
			1981: self.year_info = PTR_NEW(define_year_info ('HIN06',(self.month le  7 ? 'HIN05':'HIN07'),1B,1B,1B,1B,1B,1B,1B))
			1982: self.year_info = PTR_NEW(define_year_info ('HIN06','HIN07',1B,1B,1B,1B,1B,1B,1B))
			1983: self.year_info = PTR_NEW(define_year_info ((self.month le  4 ? 'HIN06':'HIN08'),'HIN07',1B,1B,1B,1B,1B,1B,1B))
			1984: self.year_info = PTR_NEW(define_year_info ((self.month le  6 ? 'HIN08':'nnn'),'HIN07',1B,1B,1B,1B,1B,1B,1B))
			1985: self.year_info = PTR_NEW(define_year_info ('nnn','HIN09',0B,0B,1B,1B,0B,1B,0B))
			1986: self.year_info = PTR_NEW(define_year_info ('nnn','HIN09',0B,0B,1B,1B,0B,1B,0B))
			1987: self.year_info = PTR_NEW(define_year_info ('HIN10','HIN09',1B,1B,1B,1B,1B,1B,1B))
			1988: self.year_info = PTR_NEW(define_year_info ('HIN10',(self.month le 10 ? 'HIN09':'HIN11'),1B,1B,1B,1B,1B,1B,1B))
			1989: self.year_info = PTR_NEW(define_year_info ('HIN10','HIN11',1B,1B,1B,1B,1B,1B,1B))
			1990: self.year_info = PTR_NEW(define_year_info ('HIN10','HIN11',1B,1B,1B,1B,1B,1B,1B))
			1991: self.year_info = PTR_NEW(define_year_info ((self.month le  9 ? 'HIN10':'HIN12'),'HIN11',1B,1B,1B,1B,1B,1B,1B))
			1992: self.year_info = PTR_NEW(define_year_info ('HIN12','HIN11',1B,1B,1B,1B,1B,1B,1B))
			1993: self.year_info = PTR_NEW(define_year_info ('HIN12','HIN11',1B,1B,1B,1B,1B,1B,1B))
			1994: self.year_info = PTR_NEW(define_year_info ('HIN12','HIN11',1B,1B,1B,1B,1B,1B,1B))
			1995: self.year_info = PTR_NEW(define_year_info ('HIN12','HIN14',1B,1B,1B,1B,1B,1B,1B))
			1996: self.year_info = PTR_NEW(define_year_info ('HIN12','HIN14',1B,1B,1B,1B,1B,1B,1B))
			1997: self.year_info = PTR_NEW(define_year_info ('HIN12','HIN14',1B,1B,1B,1B,1B,1B,1B))
			1998: self.year_info = PTR_NEW(define_year_info ((self.month le  9 ? 'HIN12':'HIN15'),'HIN14',1B,1B,1B,1B,1B,1B,1B))
			1999: self.year_info = PTR_NEW(define_year_info ('HIN15','HIN14',1B,1B,1B,1B,1B,1B,1B))
			2000: self.year_info = PTR_NEW(define_year_info ('HIN15','HIN14',1B,1B,1B,1B,1B,1B,1B))
			2001: self.year_info = PTR_NEW(define_year_info ('HIN15',(self.month le  3 ? 'HIN14':'HIN16'),1B,1B,1B,1B,1B,1B,1B))
			2002: self.year_info = PTR_NEW(define_year_info ('HIN15','HIN16',1B,1B,1B,1B,1B,1B,1B))
			2003: self.year_info = PTR_NEW(define_year_info ('HIN17','HIN16',1B,1B,1B,1B,1B,1B,1B))
			2004: self.year_info = PTR_NEW(define_year_info ('HIN17','HIN16',1B,1B,1B,1B,1B,1B,1B))
			2005: self.year_info = PTR_NEW(define_year_info ('HIN17','HIN16',1B,1B,1B,1B,1B,1B,1B))
			2006: self.year_info = PTR_NEW(define_year_info ('HIN17','HIN16',1B,1B,1B,1B,1B,1B,1B))
			2007: self.year_info = PTR_NEW(define_year_info ((self.month le  6 ? 'HIN17':'HIMEA'),(self.month le  5 ? 'HIN16':'nnn'),1B,1B,1B,1B,1B,1B,1B))
			2008: self.year_info = PTR_NEW(define_year_info ('HIMEA','nnn',0B,1B,0B,0B,1B,0B,1B))
			2009: self.year_info = PTR_NEW(define_year_info ('HIMEA',(self.month le  3 ? 'nnn':'HIN19'),1B,1B,1B,1B,1B,1B,1B))
			2010: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
			2011: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
			2012: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
			2013: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
			2014: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
			2015: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
			2016: self.year_info = PTR_NEW(define_year_info ('HIMEA','HIN19',1B,1B,1B,1B,1B,1B,1B))
		ENDCASE
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
		; set proper satellite names 
		satellite = [(*self.year_info).am,(*self.year_info).pm]
		no_idx = where(strmid(satellite,0,1) eq 'n' and satellite ne 'nnn',no_cnt)
		me_idx = where(strmid(satellite,0,1) eq 'm' and satellite ne 'nnn',me_cnt)
		dum_sat = satellite
		if self.clara2 then begin
			if no_cnt gt 0 then dum_sat[no_idx] = 'avn' +string(strmid(satellite[no_idx],1),format='(i2.2)')
			if me_cnt gt 0 then dum_sat[me_idx] = 'avme'+strmid(satellite[me_idx],1)
		endif else begin
			if no_cnt gt 0 then dum_sat[no_idx] = 'noaa-'+strmid(satellite[no_idx],1)
			if me_cnt gt 0 then dum_sat[me_idx] = 'metop'+strmid(satellite[me_idx],1)
		endelse
		(*self.year_info).am = dum_sat[0]
		(*self.year_info).pm = dum_sat[1]
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
		'ampm':	begin ; morning and afternoon satellites
					which_string = '_NOAA_AMPM_'
					if self.modis then 	which_string = '_TERRA-AQUA_AMPM_'
					self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
				end
		'am' : 	begin ; morning satellite
					satellite[1] = 'nnn'
					which_string = '_NOAA_0730AMPM_'
					if self.famec then 	which_string = '_ENVISAT_1030AMPM_'
					if self.atsr2 then 	which_string = '_ERS2_1030AMPM_'
					if self.aatsr then 	which_string = '_ENVISAT_1030AMPM_'
					if self.modis then 	which_string = '_TERRA_1030AMPM_'
					self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
				end
		'pm' : 	begin ; afternoon satellite
					satellite[0] = 'nnn'
					which_string = '_NOAA_0130AMPM_'
					if self.modis then 	which_string = '_AQUA_0130AMPM_'
					self -> update_node,['asc','desc']; here we take both nodes (stapel (12/2014))
				end
		'1330':	begin ; daylight node for the pm sats! (stapel (12/2014))
					satellite[0] = 'nnn'
					which_string = '_NOAA_0130PM_'
					if self.modis then	which_string = '_AQUA_0130PM_'
					self -> update_node, 'asc' ; for the pm sats 'asc' should always be the daylight node! (stapel (12/2014))
				end
		'0130':	begin ; night node for the pm sats! (stapel (12/2014))
					satellite[0] = 'nnn'
					which_string = '_NOAA_0130AM_'
					self.process_day_prds = 0l
					if self.modis then	which_string = '_AQUA_0130AM_'
					self -> update_node, 'desc' ; for the pm sats 'desc' should always be the night node! (stapel (12/2014))
				end
		'0730':	begin  ; daylight node for the am sats!  (stapel (12/2014))
					satellite[1] = 'nnn'
					which_string = '_NOAA_0730AM_'
					if self.famec then	which_string = '_ENVISAT_1030AM_'
					if self.atsr2 then 	which_string = '_ERS2_1030AM_'
					if self.aatsr then 	which_string = '_ENVISAT_1030AM_'
					if self.modis then 	which_string = '_TERRA_1030AM_'
					self -> update_node, 'desc' ; for the pm sats 'desc' should always be the daylight node! (stapel (12/2014))
				end
		'1930':	begin  ; night node for the am sats!  (stapel (12/2014))
					satellite[1] = 'nnn'
					self.process_day_prds = 0l
					which_string = '_NOAA_0730PM_'
					if self.famec then	which_string = '_ENVISAT_1030PM_'
					if self.atsr2 then	which_string = '_ERS2_1030PM_'
					if self.aatsr then	which_string = '_ENVISAT_1030PM_'
					if self.modis then	which_string = '_TERRA_1030PM_'
					self -> update_node, 'asc' ; for the pm sats 'asc' should always be the night node! (stapel (12/2014))
				end
	ENDCASE

	; satnames will be used in file_search, make sure its the same as in the l2b filenames!
	self.satnames = ( (self.hector or self.clara2) ? '' : strupcase(self.sensor)+'_') + strupcase(satellite)
	idx = where(satellite eq 'nnn',idxcnt)
	if idxcnt gt 0 then self.satnames[idx] = 'nnn'

	idx = where(self.satnames ne 'nnn',cnt)
	self.platform  = strcompress(strjoin(strupcase(satellite[idx]),','),/rem)
	self.variables = ptr_new(self -> get_l2b_varnames())
	self.outfile   = '_'+(self.meris ? 'MERIS':self.sensor)+'-'+self.algo + which_string

	file_mkdir,self.outpath+'/'+string(self.year,format='(i4.4)') +'/'

END
;-------------------------------------------------------------------------
PRO ncdf_gewex::set_product,product,current = current
	current = self.product
	self.product = product
	self->update
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
PRO ncdf_gewex::set_which, which
	self.which_file=strlowcase(which)
	self.update
END
;----------------------------------------------
; stapel (04/2017)
PRO ncdf_gewex::set_sensor
	self.sensor = 'AVHRR'
	if self.famec	then self.sensor = 'MERIS+AATSR'
; 	if self.meris	then self.sensor = 'MERIS'
	if self.atsr2	then self.sensor = 'ATSR2'
	if self.aatsr	then self.sensor = 'AATSR'
	if self.modis	then self.sensor = 'MODIS'
	if self.hector	then self.sensor = 'HIRS'
	if self.clara2	then self.sensor = 'AVHRR'
end
;-------------------------------------------------------------------------
FUNCTION ncdf_gewex::init, modis = modis, aatsr = aatsr, atsr2 = atsr2, famec = famec, clara2 = clara2, hector = hector, meris = meris

	self.famec  = keyword_set(famec) or keyword_set(meris)
	self.meris  = keyword_set(meris) ;use CTP2,CTT2,CTH2 instead of CTP,CTT,CTH
	self.modis  = keyword_set(modis)
	self.aatsr  = keyword_set(aatsr)
	self.atsr2  = keyword_set(atsr2)
	self.clara2 = keyword_set(clara2)
	self.hector = keyword_set(hector)

	self.use_cci_corrected_heights = 0						; CC4CL only, use corrected heights, e.g., "ctp_corrected" instead of "ctp"  

	self-> set_sensor

	; ncdf global attributes, change here
	; ESACCI is default
	self.climatology		= 'ESA Cloud_cci'				; only used in global attribute
	self.contact    		= 'contact.cloudcci@dwd.de'		; only used in global attribute
	self.institution		= 'Deutscher Wetterdienst'		; only used in global attribute
	self.algo       		= 'ESACCI'						; string used in output filename only
	self.version    		= 'v2.0'  						; used in filename and path , file_search() !!
	if self.clara2 then begin
		self.climatology	= 'CLARA-A2'
		self.contact    	= 'contact.cmsaf@dwd.de'
		self.institution	= 'Deutscher Wetterdienst'
		self.algo       	= 'CLARA_A2'
		self.version    	= '002'
		self.CMSAF_PATH		= 'CMA'							; this path will be searched for l2b files, only necassary for CMSAF files
	endif
	if self.hector then begin
		self.climatology	= 'HECTOR' 
		self.contact    	= 'contact.cmsaf@dwd.de'
		self.institution	= 'Deutscher Wetterdienst'
		self.algo       	= 'HECTOR'
		self.version    	= '001'
		self.CMSAF_PATH		= 'CMA'							; this path will be searched for l2b files, only necassary for CMSAF files
	endif

	self.missing_value 		= -999.							; Fillvalue used in output ncdfs
	self.calc_spatial_stdd	= 0								; calculate spatial instead of temporal stdd. (default)
	self.compress   		= 4 							; compress level for ncdf4 files [0-9]
	self.resolution 		= 1. 							; output resolution in degree (equal angle)
	; set dummies for startup
	self.year       		= 2008L
	self.month      		= 1
	self.product    		= 'CA'
	self.which_file 		= 'ampm'
	self.nodes      		= ptr_new(['asc','desc'])
	self.variables			= ptr_new('cmask')
	self.file 				= PTR_NEW('no_file')

	; ---
	; don't change this!!
	self.which_file_list 	= ['ampm','am','pm','0130','0730','1330','1930']
	; ---

	; paths, edit here!
	self.inpath = '/cmsaf/cmsaf-cld7/esa_cloud_cci/data/'+self.version+'/L3U/'
	if self.hector then self.inpath = '/cmsaf/cmsaf-cld8/HECTOR/BETA_withIASI/LEVEL2B/'
	if self.clara2 then self.inpath = '/cmsaf/cmsaf-cld7/AVHRR_GAC_2/LEVEL2B/'
	self.outpath = '/cmsaf/cmsaf-cld7/esa_cloud_cci/data/'+self.version+'/gewex/'+self.sensor+'/'
	; ---

	; !Dont change anything here. Use below procedure "remove_from_lists" to remove products!
	; Here you find all the defined variables that will be processed. Optical properties will 
	; only processed if daylight node is involved!
	; New variables need to be defined e.g. in "extract_all_data" and ...
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

	; Remove products from the above lists if necassary, e.g. CLARA-A2 has no CEM included
	; Removed products will not be processed!
	if self.clara2 then self.exclude_from_lists,['CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH'	, $
												 'CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH'	, $
												 'CEM_CP','CEMI_CREI']

	if self.famec  then self.exclude_from_lists,['CAE','CAEH','CAEM','CAEL','CAEW','CAEI','CAEIH'	, $
												 'CEM','CEMH','CEMM','CEML','CEMW','CEMI','CEMIH'	, $
												 'CEM_CP','CEMI_CREI']

	if self.hector then self.exclude_from_lists,['CAW','CAI','CAIH', 'CAEW','CAEI','CAEIH'			, $
												 'CEMW','CEMI','CEMIH','CTW','CTI','CTIH'			, $
												 'COD','CODH','CODM','CODL','CODW','CODI','CODIH'	, $
												 'CLWP','CIWP','CIWPH','CREW','CREI','CREIH'		, $
												 'CAD','CAWD','CAID','CAWR','CAIR','CAIHR','CAWDR'	, $
												 'CAIDR','COD_CP','CEMI_CREI','CODW_CREW','CODI_CREI']

	self -> get_git_hash
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
	  , cmsaf_path : '' $
	  , nodes : ptr_new() $
	  , result_path : '' $
	  , outfile : '' $
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
	  , git_commit_hash : '' $
	  , missing_value : 0. $
	  , compress : 0l $
	  , process_day_prds : 1l $
	  , modis : 0l $
	  , aatsr : 0l $
	  , atsr2 : 0l $
	  , famec : 0l $
	  , clara2 : 0l $
	  , hector : 0l $
	  , meris : 0l $
	  , use_cci_corrected_heights : 0l $
	  , sensor: '' $
	  , which : '' $
	  , calc_spatial_stdd : 0 $
	  , all_prd_list : ptr_new() $
	  , rel_prd_list : ptr_new() $
	  , hist_prd_list: ptr_new() $
	  , resolution : 1. $
        }
END
