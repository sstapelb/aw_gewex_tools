FUNCTION ncdf_gewex::_GET_DATA,product,error=error

	error=0
	ncfile = self.outpath+string(self.year,format='(i4.4)')+'/' $
	+product+self.outfile+string(self.year,format='(i4.4)')+'.nc'

	if file_test(ncfile) eq 0 then begin
		error = 1
		return,-1
	endif

	; stapel
	fileID = NCDF_Open(ncfile)
	NCDF_Varget, fileID, NCDF_Varid(fileID,'a_'+product), d
	NCDF_CLOSE, fileID

	return, d
END
;
;  calculate relative values from the other ncdf files
PRO ncdf_gewex::create_rel

	idx_which = where(self.which_file EQ self.which_file_list)
	if (*self.year_info).(idx_which+2) EQ 0 THEN BEGIN
		PRINT,'ncdf_gewex::create_rel   : '+string(self.year)+' '+self.which_file+' makes no sense!'
		RETURN
	ENDIF

	day_prd  = self.process_day_prds

	; coordinate variable dimensions :
	month   = 12l
	nlon    = long(360./self.resolution)
	nlat    = long(180./self.resolution)
	MISSING = self.missing_value[0]

	; coordinate variable arrays creation :
	dlon = findgen(nlon) - (180.0 - self.resolution/2.)
	dlat = findgen(nlat) - ( 90.0 - self.resolution/2.)
	dtim = findgen(month)

	; Sample data Reading (only monthly mean, this part has to be adapted)
	; -------------------
	ncdtot   = hash()
	ncdvar_m = hash()
	ncdvar_s = hash()
	nchisto  = hash()

	first_month_flag = hash()

	data = hash()

	ca   = self._get_data('CA',error = error)
	if error eq 1 then return
	cah  = self._get_data('CAH')
	cam  = self._get_data('CAM')
	cal  = self._get_data('CAL')
	caw  = self._get_data('CAW')
	cai  = self._get_data('CAI')
	caih = self._get_data('CAIH')
	if day_prd then cad = self._get_data('CAD')

	; data['CAHR']  = 100.* cah.(3)/FLOAT((cal.(3)+cam.(3)+cah.(3)))
	; data['CAMR']  = 100.* cam.(3)/FLOAT((cal.(3)+cam.(3)+cah.(3)))
	; data['CALR']  = 100.* cal.(3)/FLOAT((cal.(3)+cam.(3)+cah.(3)))
	; data['CAWR']  = 100.* caw.(3)/FLOAT((caw.(3)+cai.(3)))
	; data['CAIR']  = 100.* cai.(3)/FLOAT((caw.(3)+cai.(3)))
	; data['CAIHR'] = 100.* caih.(3)/FLOAT(cal.(3)+cam.(3)+cah.(3))

	; stapel changed 01/2014
	;   - sum1 should be equal to ca!
	;   - sum2 had almost only values of 1
	;     the problem was that caw and cai were wrong defined in extract_all_data 
	;   - checking now for missing values

	; sum0, sum1 and sum2 should be (are!) identical same for cawd+caid and cad
	; sum0 = FLOAT(cal+cam+cah)
	; sum2 = float(caw+cai)
	sum1 = float(ca)

	dum = 100. * cah / sum1
		dumidx = where(cah lt 0. or sum1 le 0.,dumidxcnt)
		if dumidxcnt gt 0 then dum[dumidx] = MISSING
	data['CAHR'] = dum
	dum = 100. * cam / sum1
		dumidx = where(cam lt 0. or sum1 le 0.,dumidxcnt)
		if dumidxcnt gt 0 then dum[dumidx] = MISSING
	data['CAMR'] = dum
	dum = 100. * cal / sum1
		dumidx = where(cal lt 0. or sum1 le 0.,dumidxcnt)
		if dumidxcnt gt 0 then dum[dumidx] = MISSING
	data['CALR'] = dum
	dum = 100. * caw / sum1
		dumidx = where(cai lt 0. or caw lt 0. or sum1 eq 0.,dumidxcnt)
		if dumidxcnt gt 0 then dum[dumidx] = MISSING
	data['CAWR'] = dum
	dum = 100. * cai / sum1
		dumidx = where(cai lt 0. or caw lt 0. or sum1 eq 0.,dumidxcnt)
		if dumidxcnt gt 0 then dum[dumidx] = MISSING
	data['CAIR'] = dum
	dum = 100. * caih / sum1
		dumidx = where(caih lt 0. or sum1 le 0.,dumidxcnt)
		if dumidxcnt gt 0 then dum[dumidx] = MISSING
	data['CAIHR'] = dum
	if day_prd then begin
; 		sum3 = float(cawd+caid)
		sum3 = float(cad)
		dum  = 100. * cawd / sum3
			dumidx = where(caid lt 0. or cawd lt 0. or sum3 le 0.,dumidxcnt)
			if dumidxcnt gt 0 then dum[dumidx] = MISSING
		data['CAWDR'] = dum
		dum  = 100. * caid / sum3
			dumidx = where(caid lt 0. or cawd lt 0. or sum3 le 0.,dumidxcnt)
			if dumidxcnt gt 0 then dum[dumidx] = MISSING
		data['CAIDR'] = dum
	endif

	prd_list = data.keys()

	foreach prd,prd_list do begin
		self.set_product,prd

		ncdvar_m_tmp = data.remove(prd)

		; stapel introduced. Treat nan's as missing value---
		nans = where(~finite(ncdvar_m_tmp), nan_cnt)
		if nan_cnt gt 0 then ncdvar_m_tmp[nans] = MISSING
		; -------------------------------------------------

		IF MIN(ncdvar_m_tmp) EQ MAX(ncdvar_m_tmp) THEN CONTINUE

		print,prd+' file is being generated! '

		bins = (*self.product_info).bins

		nbin = n_elements(bins) - 1
		bin_bounds = transpose([[bins[0:nbin-1]],[bins[1:*]]])
		bintab = fltarr(nbin)
		for jj = 0 , nbin -1 do begin
			bintab[jj] = (bin_bounds[0,jj]+bin_bounds[1,jj])/2.
		endfor

		; ====================
		; NetCDF File creation
		; ====================

		; netcdf output file :
		ncfile = self.outpath+string(self.year,format='(i4.4)')+'/'+ $
			 self.product+self.outfile+string(self.year,format='(i4.4)')+'.nc'
		file_mkdir,file_dirname(ncfile)

		idout=NCDF_CREATE(ncfile,/CLOBBER,/NETCDF4_FORMAT)
		;
		; NetCDF dimensions declaration
		; -----------------------------
		; number of longitude steps :
		xid = NCDF_DIMDEF(idout,'longitude',nlon)
		; number of latitude steps :
		yid = NCDF_DIMDEF(idout,'latitude',nlat)
		; number time steps :
		timeid = NCDF_DIMDEF(idout,'time',/UNLIMITED)

		; NetCDF coordinate variables declaration
		; ---------------------------------------
		; time
		idvar3 = NCDF_VARDEF(idout,'time',[timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar3,'long_name','time',/CHAR
		NCDF_ATTPUT,idout,idvar3,'units','months since '+string(self.year,format='(i4.4)')+'-01-01 00:00:00',/CHAR
		NCDF_ATTPUT,idout,idvar3,'calendar','standard',/CHAR

		; longitude
		idvar1 = NCDF_VARDEF(idout,'longitude',[xid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar1,'long_name','Longitude',/CHAR
		NCDF_ATTPUT,idout,idvar1,'units','degrees_east',/CHAR

		;latitude
		idvar2 = NCDF_VARDEF(idout,'latitude',[yid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar2,'long_name','Latitude',/CHAR
		NCDF_ATTPUT,idout,idvar2,'units','degrees_north',/CHAR

		; Monthly average
		idvar4 = NCDF_VARDEF(idout,'a_'+strUpcase(self.product),[xid,yid,timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar4,'long_name', (*self.product_info).long_name,/CHAR
		NCDF_ATTPUT,idout,idvar4,'units',(*self.product_info).unit,/CHAR
		NCDF_ATTPUT,idout,idvar4,'missing_value',MISSING,/FLOAT
		NCDF_ATTPUT,idout,idvar4,'_FillValue',MISSING,/FLOAT

		; NetCDF global attributes
		; ------------------------
		hostname = getenv('HOST')
		username = getenv('USER')

		NCDF_ATTPUT,idout,'Conventions','CF-1.6',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'title',(*self.product_info).long_name+' (GEWEX)',/GLOBAL,/CHAR
		platform = self.satellite
		idx = where(self.satnames ne 'nnn',cnt)
		if cnt gt 0 then platform = platform[idx]
		platform = strcompress(strjoin(strupcase(platform),','),/rem)
		NCDF_ATTPUT,idout,'platform',platform,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'sensor',self.sensor,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'climatoloy','ESA Cloud_cci v2.0',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'grid_resolution_in_degrees','1x1 deg',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'contact','contact.cloudcci@dwd.de',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'history',systime()+' : Generation by '+username[0]+'  on '+hostname[0],/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'institution','Deutscher Wetterdienst',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_duration','P12M',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_resolution','P1M',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_start',string(self.year,format='(i4.4)')+'0101',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_end',string(self.year,format='(i4.4)')+'1231',/GLOBAL,/CHAR

		;
		; NetCDF variables values recording
		; ---------------------------------
		NCDF_CONTROL,idout, /ENDEF
		NCDF_VARPUT,idout,idvar1,dlon
		NCDF_VARPUT,idout,idvar2,dlat
		NCDF_VARPUT,idout,idvar3,dtim
		NCDF_VARPUT,idout,idvar4,ncdvar_m_tmp

		NCDF_CLOSE,idout

		print,ncfile+'  created!'

	endforeach

END