;+
; $Id:$
; :Description:
;    returns all data of all products
;
; :Params:
;    month
;
;
;
; :Author: awalther
;-
FUNCTION ncdf_gewex::get_all_data, month

	self -> set_month,month

	nodes 		= *self.nodes
	count_nodes	= n_elements(nodes)
	MISSING		= self.missing_value[0]
	nlon  		= long(360./self.resolution)
	nlat  		= long(180./self.resolution)
	use_sp_var  = self.calc_spatial_stdd

	self.file	= ptr_new(self.get_l2b_files(count_file = count_file))
	if count_file le 1 then return,'no_data'

	day_mean  = hash()
	day_hist  = hash()
; 	day_vari  = hash()
	ca_avg    = 1
	i_count   = 0

	for i_file = 0 , count_file -1 do begin
		clock = tic(string(i_file,f='(i3.3)')+' '+(*self.file)[i_file])
		for i_node = 0,count_nodes-1 do begin ; loop over nodes

			; read data from level 2b files
			data_hash = self-> extract_all_data((*self.file)[i_file],node = nodes[i_node])
			prd_list  = data_hash.keys()

			foreach prd, prd_list do begin

				data  = data_hash.remove(prd)

				;--average---------------
				if day_mean.haskey(prd) eq 0 then day_mean[prd]= make_array([nlon,nlat,count_nodes*count_file], value = MISSING,/float)
				;------------------------

				;--histograms------------
				self.set_product,prd
				bins   = (*self.product_info).bins
				n_bins = n_elements(bins)
				if day_hist.haskey(prd) eq 0 then day_hist[prd]= make_array([nlon,nlat,n_bins-1,count_nodes*count_file], value = 0,/long)
				;------------------------

				;--spatial-variance------
				if use_sp_var then begin
					if day_vari.haskey(prd) eq 0 then day_vari[prd]= make_array([nlon,nlat,count_nodes*count_file], value = MISSING,/float)
				endif
				;------------------------

				idx = where(data GE 0,c_idx)
				if c_idx le 1  then continue
				dum      = day_mean[prd]
				avg_all  = rebin(double(data),nlon,nlat)
				if use_sp_var then avg_all2 = rebin(double(data^2),nlon,nlat) ; only needed for spatial variance
				if total(data eq MISSING) ne 0. then begin
					N        = product(size(data,/dim)/(double([nlon,nlat])))
					anz_fv   = round(rebin(double(data eq MISSING),nlon,nlat) * N)
					tot_fv   = anz_fv * double(MISSING)
					divisor  = double( N - anz_fv)
					fvidx    = where(anz_fv eq N,fvcnt)
					if fvcnt gt 0 then divisor[fvidx] = 1d
					if use_sp_var then sum2_all = ( temporary(avg_all2) * N - temporary(anz_fv) * (MISSING)^2. )
					avg_all  = ( avg_all * N - temporary(tot_fv) ) / divisor
					avg_all  = float(avg_all > 0d) ; "> 0d" removes arithm. imprecisions that should be zero; should be safe for all gewex vars
					if fvcnt gt 0 then avg_all[fvidx] = MISSING
				endif

				if strupcase(prd) eq 'CA' then ca_avg = avg_all
				;stapel; included this to make all CAE an actually CEM-weighted CA, not just a CEM! 
				if strupcase(strmid(prd,0,3)) eq 'CAE' then begin
					idx = where(avg_all eq MISSING or ca_avg eq MISSING,idxcnt)
					avg_all = avg_all * ca_avg
					if idxcnt gt 0 then avg_all[idx] = MISSING
				endif
				dum[*,*,i_count] = avg_all
				day_mean[prd]    = temporary(dum)
				;--------

				;spatial variance (stapel 03/17)
				if use_sp_var then begin
					dum     = day_vari[prd]
					var_all = ( (temporary(sum2_all) - (divisor) * temporary(avg_all)^2) > 0.) / ((temporary(divisor-1)) > 1.)
					if fvcnt gt 0 then var_all[fvidx] = MISSING
					dum[*,*,i_count] = temporary(var_all)
					day_vari[prd]    = temporary(dum)
				endif
				;--------

				;--------
				if strupcase(strmid(prd,0,3)) eq 'COD' then begin
					; all cod product values are logarithmic, but not the bins -> unlog
					idx = where(data ne MISSING,idxcnt)
					if idxcnt gt 0 then data[idx] = exp(data[idx]-10.)
				endif
				; histogram calculations moved from below to here 
				; to make sure the histogram sums "non-averaged" values (stapel 03/17)
				dum = day_hist[prd]
				FOR i_his = 0,n_bins-2 DO BEGIN
					; stapel 11/2013 email CS ; all CTP, CTT values lower 100 hpa/150K into first bin
					dd     = ( (i_his eq 0) and ( prd eq 'CP' or prd eq 'CT') )
					hh_dum =  between(data, (dd ? 0:bins[i_his]), bins[i_his+1],not_include_upper=(i_his ne (n_bins -2)))
					dum[*,*,i_his,i_count] = long(product(size(hh_dum,/dim)/float([nlon,nlat])) * rebin(float(hh_dum),nlon,nlat))
				Endfor
				day_hist[prd] = temporary(dum)
			endforeach
			undefine,ca_avg
			undefine,data_hash
			i_count++
		endfor ; ; loop over i nodes
		toc, clock
	endfor ; loop over i files l2b

	out_hash = hash()
	prd_list = day_mean.keys()
	exc_bck = !except
	!except = 0
	foreach prd , prd_list DO BEGIN

		print,'===> ' , prd,' <==== averaging over all pixels'

		day_hist_tmp = day_hist.remove(prd)
		day_mean_tmp = day_mean.remove(prd)
		if use_sp_var then day_vari_tmp = day_vari.remove(prd)

		res_count    = total(day_mean_tmp NE MISSING,3,/NAN)
		idx          = where(day_mean_tmp eq MISSING,idxcnt)
		if idxcnt gt 0 then day_mean_tmp[idx] = !VALUES.F_NAN

		res_mean     = mean(day_mean_tmp,dim=3,/nan)

		; only averaging is based on logarithmic values, but we want to write non log values into ncdf
		if strupcase(strmid(prd,0,3)) eq 'COD' then res_mean = exp(res_mean-10.)

		idx_nan = where(finite(res_mean,/NAN),idx_nancnt)
		if idx_nancnt gt 0 then res_mean[idx_nan] = MISSING

		if not use_sp_var then begin 
			; STDD 1)
			; this is the intra monthly stddev of already spatial averaged values
			if strupcase(strmid(prd,0,3)) eq 'COD' then day_mean_tmp = exp(day_mean_tmp-10.)
			res_sdev = stddev(day_mean_tmp,dim=3,/NAN)
			idx_nan  = where(finite(res_sdev,/NAN),idx_nancnt)
			if idx_nancnt gt 0 then res_sdev[idx_nan] = MISSING
		endif else begin
			; STDD 2)
			; this is a temporal averaged spatial stddeviation calculated with spatial variance
			; (see above) and uncertainty propagation method
			idx = where(day_vari_tmp eq MISSING,idxcnt)
			if idxcnt gt 0 then day_vari_tmp[idx] = !VALUES.F_NAN
			anz = total(day_vari_tmp ge 0,3,/nan) - 1.
			res_sdev = sqrt(total(day_vari_tmp,3,/nan)) /  ( anz > 1.)
			idx = where(anz eq 0,idxcnt)
			if idxcnt gt 0 then res_sdev[idx] = MISSING
		endelse

		; histograms 
		res_hist = total(day_hist_tmp,4,/nan)

		out =  { $
			n_tot: res_count $
			, f_var: 0 $
			, a_var: res_mean $
			, s_var: res_sdev $
			, h_var: res_hist $
		}

		out_hash[prd] = out

		undefine,day_hist_tmp
		undefine,day_mean_tmp
		undefine,out

	endforeach

	!except=exc_bck

	return, out_hash

end
