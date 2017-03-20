PRO ncdf_gewex::update_product

	long_name ='TO COMPLETE'
	unit ='none'
	references = 'TO COMPLETE'
	mini = 0
	maxi = 100

	; C1)  12.06.2013 stapel needed to change some bin boundaries, according to the reference: 
	; ref) http://climserv.ipsl.polytechnique.fr/gewexca/instruments/GEWEX_CA_database_v2.pdf
	case strupcase(self.product) of
		'CA':BEGIN
			long_name ='Cloud amount'
			unit ='1'
			references = 'Heidinger 2004 '
			bins = findgen(11)/10.
			maxi=1.
			mini=0.
		END
		'CAD':BEGIN
			long_name ='Cloud amount Daytime'
			unit ='1'
			references = 'Heidinger 2004 '
			bins = findgen(11)/10.
			maxi=1.
			mini=0.
		END
		; WP is not defined in reference !?
		'WP':BEGIN
			long_name = 'Total Water Path'
			unit= 'g/m2'
			references='no'
			bins=[0,5,10,15,20,25,30,40,50,100,150,200,250,300,350,400,450,500,1000,1500,2000,3000,10000]
			mini=0
			maxi=200
		END
		'CAH':BEGIN
			long_name ='High cloud amount'
			unit ='1'
			references = 'Heidinger 2004 (TO CHECK)'
			bins = findgen(11)/10.
			mini=0.2
			maxi=0.5
		END
		'CAM':BEGIN
			long_name ='Middle cloud amount'
			unit ='1'
			references = 'Heidinger 2004 (TO CHECK)'
			bins = findgen(11)/10.
			mini=0.0
			maxi=0.4
		END
		'CAL':BEGIN
			long_name ='Low cloud amount'
			unit ='1'
			references = 'Heidinger 2004 (TO CHECK)'
			bins = findgen(11)/10.
			mini=0.4
			maxi=0.7
		END 
		'CAW':BEGIN
			long_name = 'Cloud amount Water '
			unit ='1'
			references = 'TOC'
			bins = findgen(11)/10.
			mini=0.2
			maxi=0.5
		END
		'CAI':BEGIN
			long_name = 'Cloud amount Ice'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)/10.
			mini=0.2
			maxi=0.5
		END
		'CAWD':BEGIN
			long_name = 'Cloud amount Water Daytime'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)/10.
			mini=0.2
			maxi=0.5
		END
		'CAID':BEGIN
			long_name = 'Cloud amount Ice Daytime'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)/10.
			mini=0.2
			maxi=0.5
		END
		'CAIH':BEGIN
			long_name = 'Cloud amount Ice high'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)/10.
			mini=0.1
			maxi=0.5
		END
		'CAE':BEGIN
			long_name = 'Effective Cloud Amount'
			unit = '1'
			references = 'TO COMPLETE'
			bins = findgen(11)/10.
			mini=0.50
			maxi=0
		END
		'CAEH': BEGIN
			long_name ='Effective Cloud Amount High'
			unit = '1'
			referenes='AKH'
			bins=findgen(11)/10.
			mini=0.0
			maxi=0.3
		END
		'CAEM': BEGIN
			long_name ='Effective Cloud Amount Middle'
			unit = '1'
			referenes='AKH'
			bins=findgen(11)/10.
			mini=0.3
			maxi=0.6
		END
		'CAEL': BEGIN
			long_name ='Effective cloud amount Low'
			unit = '1'
			referenes='AKH'
			bins=findgen(11)/10.
			mini=0.4
			maxi=0.6
		END
		'CAEW': BEGIN
			long_name ='Effective cloud amount Water'
			unit = '1'
			referenes='AKH'
			bins=findgen(11)/10.
			mini=0.4
			maxi=0.7
		END
		'CAEI': BEGIN
			long_name ='Effective cloud amount Ice'
			unit = '1'
			referenes='AKH'
			bins=findgen(11)/10.
			mini=0.2
			maxi=0.4
		END
		'CAEIH': BEGIN 
			long_name ='Effective cloud amount Ice High'
			unit = '1'
			referenes='AKH'
			bins=findgen(11)/10.
			mini=0
			maxi=100
		END
		'CAHR':BEGIN
			long_name ='Relative high cloud amount'
			unit ='1'
			references = 'Heidinger 2004 (TO CHECK)'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CAMR':BEGIN
			long_name ='Relative middle cloud amount'
			unit ='1'
			references = 'Heidinger 2004 (TO CHECK)'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CALR':BEGIN
			long_name ='Relative low cloud amount'
			unit ='1'
			references = 'Heidinger 2004 (TO CHECK)'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END 
		'CAWR':BEGIN
			long_name = 'Relative Cloud amount water '
			unit ='1'
			references = 'TOC'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CAIR':BEGIN
			long_name = 'Relative Cloud amount ice'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CAWDR':BEGIN
			long_name = 'Relative Cloud amount water daytime'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CAIDR':BEGIN
			long_name = 'Relative Cloud amount ice daytime'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CAIHR':BEGIN
			long_name = 'Cloud amount water ice High relative'
			unit ='1'
			references = 'TOC'
			bins = findgen(11)*10.
			mini=0
			maxi=100
		END
		'CT': BEGIN
			long_name ='Cloud Top Temperature'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=240
			maxi=270
		END
		'CTH': BEGIN
			long_name ='Cloud Top Temperature High'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=220
			maxi=280
		END
		'CTM': BEGIN
			long_name ='Cloud Top Temperature Middle'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=250
			maxi=280
		END
		'CTL': BEGIN
			long_name ='Cloud Top Temperature Low'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=260
			maxi=300
		END
		'CTW': BEGIN
			long_name ='Cloud Top Temperature water phase'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=260
			maxi=300
		END
		'CTI': BEGIN
			long_name ='Cloud Top Temperature ice phase'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=200
			maxi=250
		END
		'CTIH': BEGIN
			long_name ='Cloud Top Temperature High Ice'
			unit ='K'
			references = 'TO COMPLETE'
			bins = [150,180+(findgen(27)*5),320]
			mini=200
			maxi=250
		END
		'CP':BEGIN
			long_name ='Cloud Top Pressure'
			unit ='hPa'
			references = 'Pavalonis & Heidinger 2004 (TO CHECK)'
			bins = 100 + (findgen(11) * 100)
; 			bins = [10.,180.,310.,440.,560.,680.,800.,1100.]
			mini=10
			maxi=1100
		END
		'CEM':BEGIN
			long_name ='Cloud Emissivity'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini=0.7
			maxi=1.
		END
		'CEMH':BEGIN
			long_name ='Cloud Emissivity High'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini=0.1
			maxi=0.3
		END
		'CEMM':BEGIN
			long_name ='Cloud Emissivity Middle'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini=0.05
			maxi=0.3
		END
		'CEML':BEGIN
			long_name ='Cloud Emissivity Low'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini = 0.3
			maxi=0.6
		END
		'CEMW':BEGIN
			long_name ='Cloud Emissivity water phase'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini = 0.4
			maxi=0.7
		END
		'CEMI':BEGIN
			long_name ='Cloud Emissivity ice phase'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini = 0.2
			maxi=0.4
		END
		'CEMIH':BEGIN
			long_name ='Cloud Emissivity ice phase'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [0.,0.2,0.4,0.8,0.95,1.]
			mini = 0.1
			maxi=0.3
		END
		'COD':BEGIN
			long_name ='Cloud Optical Depth'
			unit ='1'
			references = 'TO COMPLETE'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			mini= 0.
			maxi=10.	 
		END
		'CODH':BEGIN
			long_name ='Cloud Optical Depth High'
			unit ='1'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			references = 'TO COMPLETE'
		END
		'CODM':BEGIN
			long_name ='Cloud Optical Depth Middle'
			unit ='1'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			references = 'TO COMPLETE'
		END
		'CODL':BEGIN
			long_name ='Cloud Optical Depth Low'
			unit ='1'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			references = 'TO COMPLETE'
		END
		'CODW':BEGIN
			long_name ='Cloud Optical Depth Water Phase'
			unit ='1'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			references = 'TO COMPLETE'
		END
		'CODI':BEGIN
			long_name ='Cloud Optical Depth Ice Phase'
			unit ='1'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			references = 'TO COMPLETE'
		END
		'CODIH':BEGIN
			long_name ='Cloud Optical Depth Ice Phase High Ice'
			unit ='1'
			bins = [indgen(11)/10.,2,3,4,5,6,7,8,9,10,15,20,25,30,40,50,60,70,80,90,100,150,200,300,1000]
			references = 'TO COMPLETE'
		END
		'CLWP':BEGIN
			long_name ='Liquid Water Path'
			unit ='g/m2'
			references = 'TO COMPLETE'
			bins= [0,5,10,15,20,25,30,40,50,100,150,200,250,300,350,400,450,500,1000,1500,2000,3000,10000]
		END
		'CIWP':BEGIN
			long_name ='Ice Water Path'
			unit ='g/m2'
			references = 'TO COMPLETE'
			bins= [0,5,10,15,20,25,30,40,50,100,150,200,250,300,350,400,450,500,1000,1500,2000,3000,10000]
			mini=0
			maxi=100
		END
		'CIWPH':BEGIN
			long_name ='Ice Water Path High'
			unit ='g/m2'
			references = 'TO COMPLETE'
			bins= [0,5,10,15,20,25,30,40,50,100,150,200,250,300,350,400,450,500,1000,1500,2000,3000,10000]
		END
		'CREW':BEGIN
			long_name ='Cloud Effective Radius Water Phase'
			unit ='um'
			references = 'TO COMPLETE'
	;!C1		bins = [2.*findgen(13),28,30,35,40,45,50,200]
			bins = [2.*findgen(13),26,28,30,35,40,45,50,200]
			mini=0
			maxi=15
		END
		'CREI':BEGIN
			long_name ='Cloud Effective Radius Ice Phase'
			unit ='um'
			references = 'TO COMPLETE'
	;!C1		bins = [2.*findgen(13),28,30,35,40,45,50,55,60,65,70,75,80,90,100,110,120,150,200]
			bins = [2.*findgen(13),26,28,30,35,40,45,50,55,60,65,70,75,80,90,100,110,120,150,200]
			mini=0
			maxi=20
		END
		; stapel added CREIH, CZ, just to complete product list of reference
		'CREIH':BEGIN
			long_name ='Cloud Effective Radius Ice Phase High'
			unit ='um'
			references = 'TO COMPLETE'
			bins = [2.*findgen(13),26,28,30,35,40,45,50,55,60,65,70,75,80,90,100,110,120,150,200]
			mini=0
			maxi=20
		END
		'CZ':BEGIN
			long_name = 'Cloud Height'
			unit = 'km'
			references = 'TO COMPLETE'
			bins = findgen(41)/2.
			mini = 0
			maxi = 20
		END
		ELSE:
	endcase

	self.product_info = PTR_NEW( { long_name : long_name $
					, unit : unit $
					, references:references $
					, bins : bins $
					, mini : mini $
					, maxi : maxi $
	} )

END
