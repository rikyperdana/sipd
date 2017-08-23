if Meteor.isClient

	AutoForm.setDefaultTemplate 'materialize'
	currentRoute = -> Router.current().route.getName()
	wilName = ->
		kab: currentRoute().split('_')[0]
		kec: currentRoute().split('_')[1]
		kel: currentRoute().split('_')[2]
	selectElemen = -> Session.get 'selectElemen'
	searchTerm = -> Session.get 'searchTerm'

	Template.registerHelper 'coll', -> coll
	Template.registerHelper 'showContoh', -> Session.get 'showContoh'
	Template.registerHelper 'showGraph', -> Session.get 'showGraph'
	Template.registerHelper 'showMap', -> Session.get 'showMap'
	Template.registerHelper 'showAdd', -> Session.get 'showAdd'
	Template.registerHelper 'editData', -> Session.get 'editData'
	Template.registerHelper 'formMode', ->
		add = Session.get 'showAdd'
		edit = Session.get 'editData'
		true if add or edit
	Template.registerHelper 'pageTitle', ->
		kab: _.startCase wilName().kab
		kec: _.startCase wilName().kec
		kel: _.startCase wilName().kel
	Template.registerHelper 'pagins', ->
		limit = Session.get 'limit'
		length = coll.sekolahs.find().fetch().length
		modulo = length % limit
		range = length - modulo
		end = range / limit + 1
		[1..end]

	Template.body.events
		'click #showContoh': ->
			Session.set 'showContoh', not Session.get 'showContoh'
		'click #showGraph': ->
			Session.set 'showGraph', not Session.get 'showGraph'
		'click #showMap': ->
			Session.set 'showMap', not Session.get 'showMap'
		'click #showAdd': ->
			Session.set 'showAdd', not Session.get 'showAdd'
		'dblclick #row': (event, obj) ->
			Session.set 'editData', obj
		'click #close': ->
			Session.set 'showAdd', false
			Session.set 'editData', null
		'keyup #search': (event) ->
			Session.set 'searchTerm', event.target.value.toLowerCase()
		'click .num': (event) ->
			num = event.currentTarget.innerHTML
			Session.set 'pagin', num - 1
			$('.num').parent().removeClass 'active'
			$('.num#'+num).parent().addClass 'active'
		'click #prev': ->
			unless Session.get 'pagin' is 0
				Session.set 'pagin', -1 + Session.get 'pagin'
		'click #next': ->
			Session.set 'pagin', 1 + Session.get 'pagin'
		'click #mapColor': ->
			Meteor.call 'wilStat'

	Template.layout.onRendered ->
		Session.set 'pagin', 0

	Template.home.helpers
		cards: ->
			[
				title: 'Database Elemen'
				icon: 'texture'
				image: 'http://www.cortell.co.za/wp-content/uploads/2015/03/Cortell-Bus-Perf-Graph.jpg'
				route: 'kampar'
				desc: 'Pada halaman berikut anda akan mendapatkan informasi Indikator Kinerja Daerah per wilayah'
			,
				title: 'Database Sekolah'
				icon: 'school'
				image: 'http://cdn.images.express.co.uk/img/dynamic/1/590x/school-gypsies-436332.jpg'
				route: '/sekolahs'
				desc: 'Pada halaman berikut anda akan mendapatkan informasi seluruh Sekolah di Provinsi Riau'
			,
				title: 'Database Jalan'
				icon: 'directions'
				image: 'http://i.telegraph.co.uk/multimedia/archive/02419/roads_2419537b.jpg'
				route: 'jalan'
				desc: 'Pada halaman ini anda akan mendapatkan informasi Jalan Provinsi dan Jalan Nasional'
			]

	Template.wil.helpers
		datas: ->
			wils =
				kab: wilName().kab
				kec: wilName().kec
				kel: wilName().kel

			if wilName().kab and wilName().kec and not wilName().kel
				wils.kel = '*'
			else if wilName().kab is 'riau'
				wils.kab = '*'
				wils.kec = '*'
				wils.kel = '*'
			else if wilName().kab and not wilName.kec and not wilName().kel
				wils.kec = '*'
				wils.kel = '*'

			sub = Meteor.subscribe 'elemens', wils, selectElemen()
			if sub.ready()
				source = coll.elemens.find().fetch()
				if source.length < 1 and wilName().kel is '*'
					Meteor.call 'wilSum', wilName(), selectElemen(), (err, res) ->
						if res then Session.set 'wilDatas', res
					Session.get 'wilDatas'
				else
					source


	Template.wil.events
		'click #emptyElemen': ->
			dialog =
				message: 'Yakin kosongkan elemen?'
				title: 'Elemen ' + selectElemen()
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'emptyElemen', wilName(), selectElemen()
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					pecah = data.indikator.split ' '
					buang = _.reject pecah, (i) -> i.includes ')'
					data.indikator = buang.join ' '
					kab = -> if wilName().kab then wilName().kab else '*'
					kec = -> if wilName().kec then wilName().kec else '*'
					kel = -> if wilName().kel then wilName().kel else '*'
					Meteor.call 'import', 'elemens',
						kab: kab()
						kec: kec()
						kel: kel()
						elemen: _.kebabCase data.elemen
						indikator: data.indikator
						defenisi: data.defenisi
						y2015:
							tar: data.tar2015
							rel: data.rel2015
						y2016:
							tar: data.tar2016
							rel: data.rel2016
						y2017:
							tar: data.tar2017
							rel: data.rel2017
						y2018:
							tar: data.tar2018
							rel: data.rel2018
						y2019:
							tar: data.tar2019
							rel: data.rel2019

	Template.selectElemen.onRendered ->
		$('select').material_select()

	Template.selectElemen.helpers
		elemensName: -> _.map elemens, (i) -> _.startCase i

	Template.selectElemen.events
		'change select': (event) ->
			Session.set 'selectElemen', _.kebabCase event.target.value

	Template.login.events
		'submit #login': (event) ->
			event.preventDefault()
			username = event.target[0].value
			password = event.target[1].value
			Meteor.loginWithPassword username, password, (err) ->
				if err
					Materialize.toast err.reason, 4000
				else
					Router.go '/' + username

	Template.contohElemen.helpers
		elemensName: -> elemens

	Template.grafik.helpers
		grafik: ->
			barArray = []
			source = coll.elemens.find().fetch()
			if source.length > 0
				barArray.push [i.elemen, i.nilai] for i in source
			else if Session.get 'kecDatas'
				barArray.push [i.elemen, i.nilai] for i in Session.get 'kecDatas'
			else if Session.get 'kabDatas'
				barArray.push [i.elemen, i.nilai] for i in Session.get 'kabDatas'
			data: type: 'bar', columns: barArray

	Template.map.onRendered ->
		sub = Meteor.subscribe 'wilStat', wilName(), selectElemen()
		getColor = (prop) ->
			find = _.find coll.wilStat.find().fetch(), (i) ->
				kab = i.kab is _.kebabCase prop.KABUPATEN
				kec = i.kec is _.kebabCase prop.KECAMATAN
				kel = i.kel is _.kebabCase prop.DESA
				elem = i.elemen is selectElemen()
				true if kab and kec and kel and elem
			if find
				switch
					when find.avg > 100 then 'blue'
					when find.avg > 75 then 'green'
					when find.avg > 50 then 'orange'
					when find.avg > 25 then 'red'
					else 'grey'
			else
				'white'

		getOpac = (prop) ->
			if wilName().kel
				if _.kebabCase(prop.DESA) isnt wilName().kel then 0 else 0.7
			else if wilName().kec
				if _.kebabCase(prop.KECAMATAN) isnt wilName().kec then 0 else 0.7
			else if wilName().kab is 'riau'
				0.7
			else if wilName().kab
				if _.kebabCase(prop.KABUPATEN) isnt wilName().kab then 0 else 0.7
		style = (feature) ->
			color: 'black'
			weight: 0.5
			dashArray: '3'
			opacity: getOpac feature.properties
			fillColor: getColor feature.properties
			fillOpacity: getOpac feature.properties

		clickFeature = (event) ->
			map.fitBounds event.target.getBounds()

		onEachFeature = (feature, layer) ->
			layer.on
				click: clickFeature
			kab = _.kebabCase feature.properties.KABUPATEN
			kec = _.kebabCase feature.properties.KECAMATAN
			kel = _.kebabCase feature.properties.DESA
			content = '<b>Kab: </b>'+kab+'<br/>'
			content += '<b>Kec: </b>'+kec+'<br/>'
			content += '<b>Kel: </b>'+kel+'<br/>'
			detailRoute = [kab, kec, kel].join '_'
			content += '<b>Wil: </b><a href="'+detailRoute+'">Detail</a><br/>'
			find = _.find coll.wilStat.find().fetch(), (i) ->
				i.kab is kab and i.kec is kec and i.kel is kel and i.elemen is selectElemen()
			if find
				content += '<b>Sum: </b>'+find.sum+'<br/>'
				content += '<b>Count: </b>'+find.count+'<br/>'
				content += '<b>Average: </b>'+find.avg+'<br/>'
			layer.bindPopup content

		topo = L.tileLayer.provider 'OpenTopoMap'
		geojson = L.geoJson.ajax 'maps/petas.geojson',
			style: style
			onEachFeature: onEachFeature

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			zoomControl: false
			layers: [topo, geojson]

	Template.sekolahs.onRendered ->
		baseMaps =
			Topografi: L.tileLayer.provider 'OpenTopoMap'
			Jalan: L.tileLayer.provider 'OpenStreetMap.DE'
			CitraRiau: L.tileLayer.provider 'Esri.WorldImagery'
		overlays = {}

		makeLayers = (category, type, color, icon) ->
			markers = []
			for i in coll.sekolahs.find().fetch()
				if i.latlng and i[category] is type
					marker = L.marker i.latlng,
						icon: L.AwesomeMarkers.icon
							markerColor: color
							prefix: 'fa'
							icon: icon
					content = '<b>Nama: </b>' + i.nama + '<br/>'
					content += '<b>Bentuk: </b>' + i.bentuk + '<br/>'
					content += '<b>Alamat: </b>' + i.alamat + ' ' + i.keldes + '<br/>'
					content += '<b>Siswa: </b>' + i.siswa + ' orang <br/>'
					marker.bindPopup content
					markers.push marker
			overlays[type] = L.layerGroup markers

		makeLayers 'bentuk', 'SD', 'orange', 'leanpub'
		makeLayers 'bentuk', 'SMP', 'red', 'graduation-cap'
		makeLayers 'bentuk', 'SMA', 'darkred', 'university'
		makeLayers 'bentuk', 'SMK', 'darkgreen', 'cog'

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			minZoom: 8
			maxZoom: 17
			zoomControl: false
			layers: [
				baseMaps.Topografi
				overlays.SD
				overlays.SMP
				overlays.SMA
				overlays.SMK
			]

		layersControl = L.control.layers baseMaps, overlays, collapsed: false
		layersControl.addTo map
		locate = L.control.locate()
		locate.addTo map
		$('.num#1').parent().addClass 'active'

	Template.sekolahs.onRendered ->
		Session.set 'limit', 200

	Template.sekolahs.helpers
		datas: ->
			if searchTerm()
				_.filter coll.sekolahs.find().fetch(), (i) ->
					asNama = i.nama.toLowerCase().includes searchTerm()
					asAlamat = i.alamat.toLowerCase().includes searchTerm()
					asKeldes = i.keldes.toLowerCase().includes searchTerm()
					true if asNama or asAlamat or asKeldes
			else
				pagin = Session.get 'pagin'
				limit = Session.get 'limit'
				selector = {}
				options =
					limit: limit
					skip: pagin * limit
				coll.sekolahs.find(selector, options).fetch()
		stats: ->
			source = coll.sekolahs.find().fetch()
			jumlahSekolah = -> source.length
			jumlahSiswa = -> _.sumBy source, (i) -> i.siswa
			jumlahKoordinat = -> (filtered = _.filter source, (i) -> i.latlng).length

			list = [
				title: 'Jumlah Sekolah'
				content: jumlahSekolah() + ' unit'
				color: 'red'
				icon: 'account_balance'
			,
				title: 'Jumlah Siswa'
				content: jumlahSiswa() + ' orang'
				color: 'blue'
				icon: 'face'
			,
				title: 'Koordinat'
				content: jumlahKoordinat() + ' sekolah'
				color: 'green'
				icon: 'place'
			,
				title: 'Kondisi'
				content: 'SD 400, SMP 200, SMA 150'
				color: 'orange'
				icon: 'thumbs_up_down'
			]

	Template.sekolahs.events
		'click #empty': ->
			dialog =
				message: 'Yakin Kosongkan Seluruh Sekolah?'
				title: 'Kosongkan DB Sekolah'
				okText: 'Ya'
				focus: 'cancel'
				success: true
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'emptySekolahs'
		'change :file': (event) ->
			Papa.parse event.target.files[0],
				header: true
				step: (row) ->
					record = row.data[0]
					Meteor.call 'import', 'sekolahs',
						nama: record.nama
						status: record.status
						bentuk: record.bentuk
						alamat: record.alamat
						keldes: record.keldes
						siswa: record.siswa
		'click #geocode': ->
			getLatLng = (obj) ->
				geocode.getLocation obj.alamat + ' Riau', (location) ->
					obj.latlng = location.results[0].geometry.location
					Meteor.call 'updateSekolah', obj
			for i in _.shuffle coll.sekolahs.find().fetch()
				unless i.latlng then getLatLng i

	Template.mapSelect.onRendered ->
		L.Icon.Default.imagePath = '/packages/bevanhunt_leaflet/images/'
		lat = $('input[name="latlng.lat"]')
		lng = $('input[name="latlng.lng"]')
		baseMaps =
			Jalan: L.tileLayer.provider 'OpenStreetMap.DE'
			CitraRiau: L.tileLayer.provider 'Esri.WorldImagery'
		dataLoc = -> if lat.val() then [lat.val(), lng.val()] else [0.5, 101.44]
		map = L.map 'mapSelect',
			zoom: 17
			maxZoom: 17
			center: dataLoc()
			layers: [baseMaps.CitraRiau]
		currentPos = L.marker [lat.val(), lng.val()]
		currentPos.bindPopup 'Lokasi Data'
		currentPos.addTo map
		map.on 'click', (event) ->
			marker = L.marker event.latlng
			marker.bindPopup 'Lokasi Baru'
			marker.addTo map
			lat.val event.latlng.lat
			lng.val event.latlng.lng
		locate = L.control.locate()
		locate.addTo map
		layersControl = L.control.layers baseMaps, {}, collapsed: false
		layersControl.addTo map

	Template.jalan.onRendered ->
		styleProv = (feature) ->
			color: '#'+Math.random().toString(16).substr(-6)
			weight: 3
			dashArray: '3'
		onEachProv = (feature, layer) ->
			layer.on
				mouseover: (event) ->
					event.target.setStyle
						weight: 8
						color: 'white'
						dashArray: ''
					event.target.bringToFront()
				mouseout: (event) ->
					jalProv.resetStyle event.target
				click: (event) ->
					map.fitBounds event.target.getBounds()
			props = ['NAMA_RUAS', 'KAB_KOTA', 'KEC', 'TP_AWAL', 'TP_AKHIR', 'PJG_SURVEY', 'PJG_RUAS', 'STS_JALAN']
			content = ''
			for i in props
				content += '<b>'+i+': </b>'+feature.properties[i]+'<br/>'
			layer.bindPopup content
		jalProv = L.geoJson.ajax 'maps/jalan_prov.geojson', style: styleProv, onEachFeature: onEachProv

		styleNas = (feature) ->
			color: '#'+Math.random().toString(16).substr(-6)
			weight: 3
			dashArray: '3'
		onEachNas = (feature, layer) ->
			layer.on
				mouseover: (event) ->
					event.target.setStyle
						weight: 8
						color: 'white'
						dashArray: ''
					event.target.bringToFront()
				mouseout: (event) ->
					jalNas.resetStyle event.target
				click: (event) ->
					map.fitBounds event.target.getBounds()
			props = ['STATUS', 'NO', 'NO_RUAS', 'NAMA_RUAS', 'PJG_SURVEY', 'KECAMATAN', 'KELAS_JALA', 'Length']
			content = ''
			for i in props
				content += '<b>'+i+': </b>'+feature.properties[i]+'<br/>'
			layer.bindPopup content
		jalNas = L.geoJson.ajax 'maps/jalan_nas.geojson', style: styleNas, onEachFeature: onEachNas

		baseMaps =
			Citra: L.tileLayer.provider 'Esri.WorldImagery'
			WMS: L.tileLayer.wms 'https://demo.boundlessgeo.com/geoserver/ows?', layers: 'ne:ne'
		overlays =
			'Jalan Provinsi': jalProv
			'Jalan Nasional': jalNas

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			layers: [baseMaps.Citra, jalProv, jalNas]

		layersControl = L.control.layers baseMaps, overlays, collapsed: false
		layersControl.addTo map

	Template.jalan.helpers
		jalProv: -> coll.jalProv.find().fetch()
		jalNas: -> coll.jalNas.find().fetch()

	Template.jalan.events
		'change #jalProvUpload': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					Meteor.call 'import', 'jalProv',
						no_ruas: data.no_ruas
						nama_ruas: data.nama_ruas
						kab_kota: data.kab_kota
						kec: data.kec
						tp_awal: data.tp_awal
						tp_akhir: data.tp_akhir
						pjg_survey: data.pjg_survey
						sts_jalan: data.sts_jalan
						no: data.no
						aadt: data.aadts
						lebar: data.lebar
						stype: data.stype
						iri: data.iri
						sdi: data.sdi
						eirr: data.eirr
						y2016:
							lp: data['2016lp']
							cost: data['2016cost']
							el: data['2016el']
						y2017:
							lp: data['2017lp']
							cost: data['2017cost']
							el: data['2017el']
		'click #emptyJalProv': ->
			dialog =
				message: 'Yakin kosongkan Tabel Jalan Provinsi?'
				title: 'Kosongkan Tabel'
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'emptyJalProv'
		'click #openJalProv': ->
			$('#tableJalProv').removeClass 'hide'
			$('#openJalProv').addClass 'hide'

		'change #jalNasUpload': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					Meteor.call 'import', 'jalNas',
						status: data.status
						no: data.no
						tanggal: data.tanggal
						no_ruas: data.no_ruas
						nama_ruas: data.nama_ruas
						pjg_survey: data.pjg_survey
						kecamatan: data.kecamatan
						kelas_jala: data.kelas_jala
						length: data.length
		'click #emptyJalNas': ->
			dialog =
				message: 'Yakin kosongkan Tabel Jalan Nasional?'
				title: 'Kosongkan Tabel'
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'emptyJalNas'
		'click #openJalNas': ->
			$('#tableJalNas').removeClass 'hide'
			$('#openJalNas').addClass 'hide'
