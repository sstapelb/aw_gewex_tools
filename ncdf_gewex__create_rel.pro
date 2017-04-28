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

	incl_day  = self.process_day_prds
	proc_list = strupcase(*self.rel_prd_list)

	; coordinate variable dimensions :
	nmonth  = 12l
	nlon    = long(360./self.resolution)
	nlat    = long(180./self.resolution)
	MISSING = self.missing_value[0]

	; coordinate variable arrays creation :
	dlon = findgen(nlon) - (180.0 - self.resolution/2.)
	dlat = findgen(nlat) - ( 90.0 - self.resolution/2.)
	dtim = findgen(nmonth)

	data = hash()

	; sum0, sum1 and ca should be (are!) identical, same for cawd+caid and cad
	; sum0 = FLOAT(cal+cam+cah)
	; sum1 = float(caw+cai)
	foreach prd, proc_list do begin
		if total(prd eq ['CAWDR','CAIDR']) then begin ; day products
			if incl_day eq 0 then continue
			if n_elements(cad) eq 0 then begin
				cad = self._get_data('CAD',error = error)
				if error eq 1 then begin
					undefine, cad
					continue
				endif else sum = float(cad)
			endif else sum = float(cad)
		endif else begin
			if n_elements(ca) eq 0 then begin
				ca   = self._get_data('CA',error = error)
				if error eq 1 then begin
					undefine, ca
					continue
				endif else sum = float(ca)
			endif else sum = float(ca)
		endelse
		raw  = self._get_data(strmid(prd,0,strlen(prd)-1),error = error)
		if error eq 0 then begin
			dumidx = where(raw lt 0. or sum le 0.,dumidxcnt,complement=gidx,ncomplement=gidxcnt)
			rel = raw * 0. + MISSING
			if gidxcnt gt 0 then rel[gidx] = 100. * raw[gidx] / sum[gidx]
			data[prd] = rel
		endif
	endforeach

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
		git_hash = self.git_commit_hash ne '' ? ' (Git commit hash: '+self.git_commit_hash+')' : ''
		c_height = (self.use_cci_corrected_heights ? ' (incl. corrected heights)' : '')

		NCDF_ATTPUT,idout,'Conventions','CF-1.6',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'title',(*self.product_info).long_name+' (GEWEX)',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'platform',self.platform,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'sensor',self.sensor,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'climatology',self.climatology+' '+self.version+c_height,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'grid_resolution_in_degrees',string(self.resolution,f='(f3.1)'),/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'contact',self.contact,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'history',systime()+': Generated by '+username[0]+' on '+hostname[0]+git_hash,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'institution',self.institution,/GLOBAL,/CHAR
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
