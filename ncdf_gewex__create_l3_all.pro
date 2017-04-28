;+
; :Description:
;    Describe the procedure.
;
;
;   creates all GEWEX products
;
;
; :Author: awalther
;  $Id:$
;-
PRO ncdf_gewex::create_l3_all

	idx_which = where(self.which_file eq self.which_file_list)
	if (*self.year_info).(idx_which+2) eq 0 then begin
		print,'ncdf_gewex::create_l3_all: '+string(self.year)+' '+self.which_file+' makes no sense!'
		return
	endif

	; coordinate variable dimensions :
	nmonth  = 12l
	nlon    = long(360./self.resolution)
	nlat    = long(180./self.resolution)
	MISSING = self.missing_value[0]

	; coordinate variable arrays creation :
	dlon = findgen(nlon) - (180.0 - self.resolution/2.)
	dlat = findgen(nlat) - ( 90.0 - self.resolution/2.)
	dtim = findgen(nmonth)

	; variable array declarations
	ncdtot   = hash()
	ncdvar_m = hash()
	ncdvar_s = hash()
	nchisto  = hash()

	; need a dummy hash to find out which products are generated
	first_month_flag = hash()

	for imois= 0, nmonth-1 do begin

		print,self.product+'  '+themonths(imois+1)+'  "'+self.which_file+'"  '+string(self.year,format='(i4.4)')

		binvar = self->get_all_data(imois+1)

		if size(binvar,/tname) eq 'STRING' then continue

		prd_list = binvar.keys()

		foreach prd,prd_list do begin

			self -> set_product,prd
			data_prd = binvar.remove(prd)

			if not first_month_flag.hasKey(prd) then begin

				bins = (*self.product_info).bins
				nbin = n_elements(bins) - 1

				nchisto_tmp   = make_array([nlon,nlat,nbin,nmonth],/LONG,VALUE=0l)
				ncdtot_tmp    = make_array([nlon,nlat,nmonth],/FLOAT,VALUE=MISSING)
				ncdvar_m_tmp  = make_array([nlon,nlat,nmonth],/FLOAT,VALUE=MISSING)
				ncdvar_n_tmp  = make_array([nlon,nlat,nmonth],/FLOAT,VALUE=MISSING)
				ncdvar_s_tmp  = make_array([nlon,nlat,nmonth],/FLOAT,VALUE=MISSING)

				ncdtot_tmp[*,*,imois]    = data_prd.n_tot
				ncdvar_m_tmp[*,*,imois]  = data_prd.a_var
				ncdvar_s_tmp[*,*,imois]  = data_prd.s_var
				nchisto_tmp[*,*,*,imois] = data_prd.h_var

				ncdtot[prd]   = ncdtot_tmp
				ncdvar_m[prd] =  ncdvar_m_tmp
				ncdvar_s[prd] = ncdvar_s_tmp
				nchisto[prd]  = nchisto_tmp

				undefine,ncdtot_tmp
				undefine,ncdvar_m_tmp
				undefine,ncdvar_s_tmp
				undefine,nchisto_tmp

				first_month_flag[prd] = 1
			endif else begin

				ncdtot_tmp   = ncdtot.remove(prd)   
				ncdvar_m_tmp = ncdvar_m.remove(prd) 
				ncdvar_s_tmp = ncdvar_s.remove(prd) 
				nchisto_tmp  = nchisto.remove(prd)  

				ncdtot_tmp[*,*,imois]    = data_prd.n_tot
				ncdvar_m_tmp[*,*,imois]  = data_prd.a_var
				ncdvar_s_tmp[*,*,imois]  = data_prd.s_var
				nchisto_tmp[*,*,*,imois] = data_prd.h_var

				ncdtot[prd]   = ncdtot_tmp
				ncdvar_m[prd] = ncdvar_m_tmp
				ncdvar_s[prd] = ncdvar_s_tmp
				nchisto[prd]  = nchisto_tmp

				undefine,ncdtot_tmp
				undefine,ncdvar_m_tmp
				undefine,ncdvar_s_tmp
				undefine,nchisto_tmp

			endelse
		endforeach

		undefine,binvar

	endfor  ; months

	prd_list = nchisto.keys()

	; make files for each product
	foreach prd,prd_list do begin
		self.set_product,prd

		ncdtot_tmp   = ncdtot.remove(prd)   
		ncdvar_m_tmp = ncdvar_m.remove(prd) 
		ncdvar_s_tmp = ncdvar_s.remove(prd) 
		nchisto_tmp  = nchisto.remove(prd)  

		if max(ncdtot_tmp) eq 0 then continue 
		if min(ncdvar_m_tmp) eq max(ncdvar_m_tmp) then continue

		print,prd+' file is being generated! '

		bins = (*self.product_info).bins
		nbin = n_elements(bins) - 1
		bin_bounds = transpose([[bins[0:nbin-1]],[bins[1:*]]])
		bintab = fltarr(nbin)
		for jj = 0 , nbin -1 do begin
			bintab[jj] = (bin_bounds[0,jj]+bin_bounds[1,jj])/2.
		endfor

		if max(ncdtot_tmp) eq 0 then return
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

		; number of bin for histogram X-Axis :
		binid = NCDF_DIMDEF(idout,'bin',nbin)

		; number of boundaries for one bin :
		nv = NCDF_DIMDEF(idout,'nv',2)
		;
		; NetCDF coordinate variables declaration
		; ---------------------------------------
		; longitude
		idvar1 = NCDF_VARDEF(idout,'longitude',[xid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar1,'long_name','Longitude',/CHAR
		NCDF_ATTPUT,idout,idvar1,'units','degrees_east',/CHAR

		;latitude
		idvar2 = NCDF_VARDEF(idout,'latitude',[yid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar2,'long_name','Latitude',/CHAR
		NCDF_ATTPUT,idout,idvar2,'units','degrees_north',/CHAR

		; time
		idvar3 = NCDF_VARDEF(idout,'time',[timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar3,'long_name','time',/CHAR
		NCDF_ATTPUT,idout,idvar3,'units','months since '+string(self.year,format='(i4.4)')+'-01-01 00:00:00',/CHAR
		NCDF_ATTPUT,idout,idvar3,'calendar','standard',/CHAR

		; bin centers
		idvar5 = NCDF_VARDEF(idout,'bin',[binid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar5,'long_name', (*self.product_info).long_name,/CHAR
		NCDF_ATTPUT,idout,idvar5,'units',(*self.product_info).unit,/CHAR
		NCDF_ATTPUT,idout,idvar5,'bounds','bin_bounds',/CHAR
		NCDF_ATTPUT,idout,idvar5,'axis','Z',/CHAR

		; bin boundaries
		idvar6 = NCDF_VARDEF(idout,'bin_bounds',[nv,binid],/FLOAT,gzip=self.compress)
		;
		; NetCDF variable declaration
		; ----------------------------
		; Monthly average 
		idvar4 = NCDF_VARDEF(idout,'a_'+strUpcase(self.product),[xid,yid,timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar4,'long_name', (*self.product_info).long_name,/CHAR
		NCDF_ATTPUT,idout,idvar4,'units',(*self.product_info).unit,/CHAR
		NCDF_ATTPUT,idout,idvar4,'missing_value',MISSING,/FLOAT
		NCDF_ATTPUT,idout,idvar4,'_FillValue',MISSING,/FLOAT

		; total number of observations
		idvar8 = NCDF_VARDEF(idout,'n_tot',[xid,yid,timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar8,'long_name','number of orbit passages',/CHAR
		NCDF_ATTPUT,idout,idvar8,'units','1',/CHAR
		NCDF_ATTPUT,idout,idvar8,'missing_value',MISSING,/FLOAT
		NCDF_ATTPUT,idout,idvar8,'_FillValue',MISSING,/FLOAT

		; number of retrieved values
		idvar9 = NCDF_VARDEF(idout,'f_'+strUpcase(self.product),[xid,yid,timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar9,'long_name','percentage of retrieved pixels out of cloudy pixels',/CHAR
		NCDF_ATTPUT,idout,idvar9,'units','1',/CHAR
		NCDF_ATTPUT,idout,idvar9,'missing_value',MISSING,/FLOAT
		NCDF_ATTPUT,idout,idvar9,'_FillValue',MISSING,/FLOAT

		; Monthly standard deviation 
		idvar10 = NCDF_VARDEF(idout,'s_'+strUpcase(self.product),[xid,yid,timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar10,'long_name','monthly standard deviation',/CHAR
		NCDF_ATTPUT,idout,idvar10,'units',(*self.product_info).unit,/CHAR
		NCDF_ATTPUT,idout,idvar10,'missing_value',MISSING,/FLOAT
		NCDF_ATTPUT,idout,idvar10,'_FillValue',MISSING,/FLOAT

		if n_elements(binid) gt 0 then begin
			; Histogram
			idvar7 = NCDF_VARDEF(idout,'h_'+strUpcase(self.product),[xid,yid,binid,timeid],/FLOAT,gzip=self.compress)
			NCDF_ATTPUT,idout,idvar7,'long_name','Monthly histograms',/CHAR
			NCDF_ATTPUT,idout,idvar7,'units',(*self.product_info).unit,/CHAR
			NCDF_ATTPUT,idout,idvar7,'missing_value',MISSING,/FLOAT
			NCDF_ATTPUT,idout,idvar7,'_FillValue',MISSING,/FLOAT
			NCDF_ATTPUT,idout,idvar7,'cell_methods','bin: sum',/CHAR
		endif
		;
		; NetCDF global attributes
		; ------------------------

		hostname = getenv("HOST")
		username = getenv("USER")
		git_hash = self.git_commit_hash ne '' ? ' (Git commit hash: '+self.git_commit_hash+')' : ''

		NCDF_ATTPUT,idout,'Conventions','CF-1.6',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'title',(*self.product_info).long_name+' (GEWEX)',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'platform',self.platform,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'sensor',self.sensor,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'climatology',self.climatology+' '+self.version,/GLOBAL,/CHAR
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
		NCDF_VARPUT,idout,idvar5,bintab
		NCDF_VARPUT,idout,idvar6,bin_bounds
		NCDF_VARPUT,idout,idvar4,ncdvar_m_tmp
		NCDF_VARPUT,idout,idvar7,nchisto_tmp
		NCDF_VARPUT,idout,idvar8,ncdtot_tmp
		NCDF_VARPUT,idout,idvar9,ncdvar_n_tmp
		NCDF_VARPUT,idout,idvar10,ncdvar_s_tmp
		;
		NCDF_CLOSE,idout
		;
		print,ncfile+'  created!'
	endforeach

end
