@aw_precompile.pro
;---------------------------------------------------------------------------------------------------------------------------------------
pro start_aw_gewex, year, which = which, list = list, modis = modis, aatsr = aatsr, atsr2 = atsr2, famec = famec

	;# Requires IDL 8.3 or higher #
	;# Make sure you have at least 10GB RAM available#

	mem_cur   = memory(/current)
	starttime = systime(1)

		default,year , 2008
		default,which,['pm','am','1330','0130','0730','1930','ampm']

		; if not keyword_set(list) and year is a 2 elemented array then year = [start_year,end_year]
		year_list = (~keyword_set(list) and n_elements(year) eq 2) ? indgen((year[1]-year[0])+1)+year[0] : year 

		print,'Start ncdf_gewex: '+strjoin(which,',')+' for '+strjoin(string(year_list,f='(i4.4)'),',')

		obj = obj_new('ncdf_gewex', modis = modis, aatsr = aatsr, atsr2 = atsr2, famec = famec)
		for yy = 0, n_elements(year_list) -1 do begin
			obj.set_year, year_list[yy]
			for wh = 0,n_elements(which) -1 do begin
				clock = TIC('"which = ' + which[wh]+'"')
				obj.set_which, which[wh]
				obj.create_l3_all
				obj.create_rel
				obj.histogram
				TOC, clock
			endfor
		endfor
		obj_destroy, obj

	caldat, systime(/utc, /julian), mo, da, ye, ho, mi, se
	dat_str	= string(da, mo, ye, ho, mi, format = '(i2.2,".",i2.2,".",i4.4," ",i2.2,":",i2.2,"[UTC] / ")')
	print, dat_str + 'NCDF_GEWEX -> '+string((systime(1)-starttime)/3600.,f='("Duration        : ", f7.3, " hrs")')
	print, dat_str + 'NCDF_GEWEX -> '+string(float(memory(/highwater)-mem_cur)/1024.^3,f='("Memory required : ", f7.3, " GiB")')

end
;---------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------
