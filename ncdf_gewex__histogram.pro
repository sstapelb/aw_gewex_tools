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
PRO ncdf_gewex::histogram

	idx_which = where(self.which_file eq self.which_file_list)
	if (*self.year_info).(idx_which+2) eq 0 then begin
		print,'ncdf_gewex::histogram    : '+string(self.year)+' '+self.which_file+' makes no sense!'
		return
	endif

	; Decision; No histograms will be processed for night-only nodes (which_file: '0130','1930')
	; Also no AMPM will be created, you can sum up "AM"+"PM" to get "AMPM"
	if ~total(self.which_file eq ['1330','0730','am','pm']) then begin
		print,"ncdf_gewex::histogram    : Histograms will only be processed for which= ['1330','0730','AM','PM']!"
		return
	endif

	nmonth = 12l
	nlon   = long(360./self.resolution)
	nlat   = long(180./self.resolution)

	; coordinate variable arrays creation :
	dlon = findgen(nlon) - (180.0 - self.resolution/2.)
	dlat = findgen(nlat) - ( 90.0 - self.resolution/2.)
	dtim = findgen(nmonth)

	nodes 	    = *self.nodes
	count_nodes = n_elements(nodes)

	prd_list = *self.hist_prd_list

	foreach prd,prd_list do begin
		combi       = strsplit(prd,'_',/ext)
		last_letter = strlowcase(strmid(combi[0],0,1,/re))
		info1       = self.histogram_info(combi[0])
		info2       = self.histogram_info(combi[1])
		nbin        = n_elements(info1.bins)-1
		nbin2       = n_elements(info2.bins)-1
		binlat      = (info1.bins[1:*]-info1.bins[0:*])/2. + info1.bins
		binlat2     = (info2.bins[1:*]-info2.bins[0:*])/2. + info2.bins
		bin_bounds  = transpose([[(info1.bins)[0:nbin-1 ]],[(info1.bins)[1:*]]])
		bin2_bounds = transpose([[(info2.bins)[0:nbin2-1]],[(info2.bins)[1:*]]])

		nc2histo    = Ulonarr(nlon,nlat,nbin,nbin2,nmonth)

		vars = self.get_l2b_varnames(combi)
		if vars.haskey('ILLUM') then vars.remove,'ILLUM'
		if 	(total(vars.haskey([info1.hash_key,info2.hash_key])) ne 2.) or $
			(total(last_letter EQ ['i','w'] and ~vars.haskey('CPH'))  ) then begin
			print,'Something went wrong! Check get_l2b_varnames!'
			stop
		endif

		FOR mm = 1 , nmonth Do Begin

			self -> set_month,mm

			print,string(self.year,format='(i4.4)')+' '+themonths(self.month)+' '+prd+' "'+strupcase(self.which_file)+'"'

			file_cld = self.get_l2b_files(count = count_file)

			FOR ff = 0, count_file -1 DO BEGIN
				if !version.release ge '8.3' then clock = tic(string(ff,f='(i3.3)')+' '+file_cld[ff])
				for i_node = 0,count_nodes-1 do begin
					; get variable hash
					struc = self.read_l2b_data(file_cld[ff],variables = vars, found = found, node=nodes[i_node])
					; if not all variables found then do nothing
					if ~found then continue
					; read vars
					prop1 = struc.remove(info1.hash_key)
					prop2 = struc.remove(info2.hash_key)
					IF struc.haskey('CPH') THEN BEGIN
						phase = ( struc.remove('CPH') eq (last_letter EQ 'w' ? 1 : 2) )
					ENDIF else phase = ( byte(prop1) * 0b + 1b )

					FOR pp1 = 0,nbin-1 DO BEGIN
						FOR pp2 = 0,nbin2-1 DO BEGIN
							dum =  between(prop1,info1.bins[pp1], info1.bins[pp1+1]) $
									AND   between(prop2,info2.bins[pp2], info2.bins[pp2+1]) $
									AND (phase eq 1b)
							nc2histo[*,*,pp1,pp2,mm-1] += ulong(product(size(dum,/dim)/float([nlon,nlat])) * rebin(float(dum),nlon,nlat))
						Endfor ; pp2
					Endfor ; pp1
				endfor ; nodes
				if !version.release ge '8.3' then toc, clock
			endfor ;files
		ENDFOR ; months

		; stapel changed to cci, removed HIST_2D from filename (email CS ) 
		ncfile = self.outpath+string(self.year,format='(i4.4)')+'/'+ prd + $
				 self.outfile+string(self.year,format='(i4.4)')+'.nc'

		FILE_MKDIR,file_dirname(ncfile)

		idout=NCDF_CREATE(ncfile,/CLOBBER,/NETCDF4_FORMAT)
		;
		; NetCDF dimensions declaration
		; -----------------------------
		; number time steps :
		timeid = NCDF_DIMDEF(idout,'time',/UNLIMITED)
		lonID  = NCDF_DIMDEF(idout,'longitude',nlon)
		latID  = NCDF_DIMDEF(idout,'latitude',nlat)
		; sstapelb 06.08.2013 changed due to email claudia stubenrauch
		binid  = NCDF_DIMDEF(idout,'binx',nbin)
		bin2id = NCDF_DIMDEF(idout,'biny',nbin2)
		; number of boundaries for one bin :
		nv = NCDF_DIMDEF(idout,'nv',2)
		;
		; NetCDF coordinate variables declaration
		; ---------------------------------------
		; time
		idvar3 = NCDF_VARDEF(idout,'time',[timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar3,'long_name','time',/CHAR
		NCDF_ATTPUT,idout,idvar3,'units','months since '+string(self.year,format='(i4.4)')+'-01-01 00:00:00',/CHAR
		NCDF_ATTPUT,idout,idvar3,'calendar','standard',/CHAR

		idvar1 = NCDF_VARDEF(idout,'longitude',[lonid,latid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar1,'long_name','Longitude',/CHAR
		NCDF_ATTPUT,idout,idvar1,'units','degrees_east',/CHAR
		idvar2 = NCDF_VARDEF(idout,'latitude',[lonid,latid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar2,'long_name','Latitude',/CHAR
		NCDF_ATTPUT,idout,idvar2,'units','degrees_north',/CHAR

		; bins centers
; 		sstapelb 06.08.2013 changed bin to binx due to email claudia stubenrauch
		idvar5 = NCDF_VARDEF(idout,'binx',[binid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar5,'long_name',info1.long_name,/CHAR
		NCDF_ATTPUT,idout,idvar5,'units',info1.unit,/CHAR
		NCDF_ATTPUT,idout,idvar5,'bounds','binx_bounds',/CHAR
 		NCDF_ATTPUT,idout,idvar5,'axis','x',/CHAR

		; bin2s centers
; 		sstapelb 06.08.2013 changed bin2 to biny due to email claudia stubenrauch
		idvar52 = NCDF_VARDEF(idout,'biny',[bin2id],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar52,'long_name',info2.long_name,/CHAR
		NCDF_ATTPUT,idout,idvar52,'units',info2.unit,/CHAR
		NCDF_ATTPUT,idout,idvar52,'bounds','biny_bounds',/CHAR
 		NCDF_ATTPUT,idout,idvar52,'axis','y',/CHAR

		; bins boundaries
; 		sstapelb 06.08.2013 changed bin_bounds to binx_bounds due to email claudia stubenrauch
 		idvar6 = NCDF_VARDEF(idout,'binx_bounds',[nv,binid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar6,'long_name',info1.long_name,/CHAR
		NCDF_ATTPUT,idout,idvar6,'units',info1.unit,/CHAR

		; bins boundaries
; 		sstapelb 06.08.2013 changed bin2_bounds to biny_bounds due to email claudia stubenrauch
		idvar7 = NCDF_VARDEF(idout,'biny_bounds',[nv,bin2id],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar7,'long_name',info2.long_name,/CHAR
		NCDF_ATTPUT,idout,idvar7,'units',info2.unit,/CHAR
		;
		; NetCDF variables declaration
		; ----------------------------
		; Histogram 2
		idvar9 = NCDF_VARDEF(idout,'h_'+prd,[lonID,latID,binid,bin2id,timeid],/FLOAT,gzip=self.compress)
		NCDF_ATTPUT,idout,idvar9,'long_name',info1.long_name+' ' +info2.long_name,/CHAR
		NCDF_ATTPUT,idout,idvar9,'units','1',/CHAR
		NCDF_ATTPUT,idout,idvar9,'missing_value',-999.,/FLOAT
		NCDF_ATTPUT,idout,idvar9,'_FillValue',-999.,/FLOAT
		NCDF_ATTPUT,idout,idvar9,'cell_methods','bin: sum',/CHAR
		;
		; NetCDF global attributes
		; ------------------------
		hostname = getenv('HOST')
		username = getenv('USER')
		git_hash = self.git_commit_hash ne '' ? ' (Git commit hash: '+self.git_commit_hash+')' : ''
		c_height = (self.use_cci_corrected_heights ? ' (incl. corrected heights)' : '')

		NCDF_ATTPUT,idout,'Conventions','CF-1.6',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'title',info1.long_name+' ' +info2.long_name+' PDF (GEWEX)',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'platform',self.platform,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'sensor',self.sensor,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'climatology',self.climatology+' '+self.version+c_height,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'grid_resolution_in_degrees',string(self.resolution,f='(f3.1)'),/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'contact',self.contact,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'history',systime()+': Generated by '+username+' on '+hostname+git_hash,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'institution',self.institution,/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_duration','P12M',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_resolution','P1M',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_start',string(self.year,format='(i4.4)')+'0101',/GLOBAL,/CHAR
		NCDF_ATTPUT,idout,'time_coverage_end',string(self.year,format='(i4.4)')+'1231',/GLOBAL,/CHAR
		;
		; NetCDF variables values recording
		; ---------------------------------
		NCDF_CONTROL,idout, /ENDEF
		NCDF_VARPUT,idout,idvar3,dtim
		NCDF_VARPUT,idout,idvar1,dlon
		NCDF_VARPUT,idout,idvar2,dlat
		NCDF_VARPUT,idout,idvar5,binlat
		NCDF_VARPUT,idout,idvar52,binlat2
		NCDF_VARPUT,idout,idvar6,bin_bounds
		NCDF_VARPUT,idout,idvar7,bin2_bounds
		NCDF_VARPUT,idout,idvar9,nc2histo
		;
		NCDF_CLOSE,idout

	endforeach
END
