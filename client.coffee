if Meteor.isClient

	AutoForm.setDefaultTemplate 'materialize'
	currentRoute = -> Router.current().route.getName()
	wilName = ->
		kab: currentRoute().split('_')[0]
		kec: currentRoute().split('_')[1]
		kel: currentRoute().split('_')[2]
	selectElemen = -> Session.get 'selectElemen'
	selectYear = -> Session.get 'selectYear'
	searchTerm = -> Session.get 'searchTerm'

	Template.registerHelper 'coll', -> coll
	Template.registerHelper 'currentRoute', -> currentRoute()
	Template.registerHelper 'routeIs', (name) -> currentRoute() is name
	Template.registerHelper 'switch', (param) -> Session.get param
	Template.registerHelper 'editData', -> Session.get 'editData'
	Template.registerHelper 'stringify', (obj) -> JSON.stringify obj
	Template.registerHelper 'formMode', ->
		add = Session.get 'showAdd'
		edit = Session.get 'editData'
		true if add or edit
	Template.registerHelper 'wilName', -> wilName()
	Template.registerHelper 'startCase', (name) -> _.startCase name
	Template.registerHelper 'pagins', ->
		limit = Session.get 'limit'
		length = coll.fasilitas.find().fetch().length
		modulo = length % limit
		range = length - modulo
		end = range / limit + 1
		[1..end]

	Template.menu.onRendered ->
		$('.collapsible').collapsible()
	
	Template.menu.helpers
		routeIn: (arr) -> _.find arr, (i) -> i is currentRoute()
		elemens: -> elemens
		kabs: -> kabs
		fasilitas: -> _.keys(headings)
		inds: -> inds
		indsname: -> indsname

	Template.body.events
		'click #switch': (event) ->
			param = event.target.attributes.param.nodeValue
			Session.set param, not Session.get param
		'dblclick #row': (event, obj) ->
			Session.set 'editData', obj
		'click #close': ->
			Session.set 'showAdd', false
			Session.set 'editData', null
		'keypress #search': (event) ->
			if event.key is 'Enter'
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
		'click #wilSum': -> Meteor.call 'wilSum'
		'click #wilStat': -> Meteor.call 'wilStat'

	Template.layout.onRendered ->
		Session.set 'pagin', 0

	Template.home.onRendered ->
		$('.parallax').parallax()
		$('.slider').slider height: 300

	Template.home.helpers
		blocks: -> blocks

	Template.wil.helpers
		datas: ->
			if wilName().kel
				selector = kab: wilName().kab, kec: wilName().kec, kel: wilName().kel
			else if wilName().kec
				selector = kab: wilName().kab, kec: wilName().kec, kel: '*'
			else if wilName().kab is 'riau'
				selector = kab: '*'
			else if wilName().kab
				selector = kab: wilName().kab, kec: '*', kel: '*'
			if selectElemen()
				selector.elemen = selectElemen()
			if searchTerm()
				selector.indikator = $regex: '.*'+searchTerm()+'.*', $options: '-i'
			options = {}
			sub = Meteor.subscribe 'coll', 'elemens', selector, options
			if sub.ready()
				coll.elemens.find().fetch()

		round: (number) -> Math.round number

	Template.wil.events
		'click #empty': (event) ->
			param = event.target.attributes.param.nodeValue
			dialog =
				message: 'Yakin kosongkan '+param+'?'
				title: 'Kosongkan ' + _.startCase param
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				selector = {}
				if param is 'elemens'
					kab = if wilName().kab then wilName().kab else '*'
					kec = if wilName().kec then wilName().kec else '*'
					kel = if wilName().kel then wilName().kel else '*'
					selector = kab: kab, kec: kec, kel: kel, elemen: selectElemen()
				if ok then Meteor.call 'empty', param, selector
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				complete: (results) ->
					datas = results.data
					kab = -> if wilName().kab then wilName().kab else '*'
					kec = -> if wilName().kec then wilName().kec else '*'
					kel = -> if wilName().kel then wilName().kel else '*'
					for i in datas
						if i.indikator
							selector =
								kab: kab()
								kec: kec()
								kel: kel()
								elemen: _.kebabCase i.elemen
								defenisi: i.defenisi
								indikator: i.indikator
							modifier = {}
							for j in [2015..2019]
								modifier['y'+j] =
									tar: parseInt i['tar'+j]
									rel: parseInt i['rel'+j]
							Meteor.call 'import', 'elemens', selector, modifier

	Template.selectElemen.onRendered ->
		$('select').material_select()

	Template.selectElemen.helpers
		elemensName: -> _.map elemens, (i) -> _.startCase i
		years: -> _.map [2015..2019], (i) -> 'y' + i

	Template.selectElemen.events
		'change #elemen': (event) ->
			Session.set 'selectElemen', _.kebabCase event.target.value
		'change #year': (event) ->
			Session.set 'selectYear', event.target.value

	Template.login.onRendered ->
		$('.slider').slider()

	Template.login.events
		'submit #login': (event) ->
			event.preventDefault()
			username = event.target[0].value
			password = event.target[1].value
			Meteor.loginWithPassword username, password, (err) ->
				if err
					Materialize.toast err.reason, 4000
				else
					Router.go '/'

	Template.contohElemen.helpers
		elemensName: -> elemens

	Template.grafik.helpers
		grafik: ->
			barArray = []
			find = _.find inds, (i) -> i.name is currentRoute()
			if find
				selector = grup: currentRoute()
				for i in coll.ind.find(selector).fetch()
					arr = [i.sasaran]
					for j in [2013..2016]
						arr.push parseInt i['y'+j].rel
					barArray.push arr
			else
				for i in coll.elemens.find().fetch()
					arr = [i.elemen]
					for j in [2015..2019]
						arr.push i['y'+j].rel
					barArray.push arr
			data: type: 'bar', columns: barArray

	Template.map.onRendered ->
		selector = elemen: selectElemen()
		unless wilName().kab is 'riau'
			if wilName().kab then selector.kab = wilName().kab
			if wilName().kec then selector.kec = wilName().kec
			if wilName().kel then selector.kel = wilName().kel
		sub = Meteor.subscribe 'coll', 'wilStat', selector, {}
		getColor = (prop) ->
			find = _.find coll.wilStat.find().fetch(), (i) ->
				kab = -> i.kab is _.kebabCase prop.KABUPATEN
				kec = -> i.kec is _.kebabCase prop.KECAMATAN
				kel = -> i.kel is _.kebabCase prop.DESA
				allKab = -> i.kab is '*'
				allKec = -> i.kec is '*'
				allKel = -> i.kel is '*'
				elem = -> i.elemen is selectElemen()
				if wilName().kel
					true if kab() and kec() and kel() and elem()
				else if wilName().kec
					true if kab() and kec() and elem() and allKel()
				else if wilName().kab is 'riau'
					true if elem() and allKab() and allKec() and allKel()
				else if wilName().kab
					true if kab() and elem() and allKec() and allKel()
			if find
				switch
					when find[selectYear()].avgKin > 0.66 then 'green'
					when find[selectYear()].avgKin > 0.33 then 'orange'
					else 'red'
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
				content += '<b>Sum: </b>'+find[selectYear()].sumKin+'<br/>'
				content += '<b>Count: </b>'+find.indikator+'<br/>'
				content += '<b>Average: </b>'+find[selectYear()].avgKin+'<br/>'
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

	Template.fasilitas.onRendered ->
		baseMaps =
			Topografi: L.tileLayer.provider 'OpenTopoMap'
			Jalan: L.tileLayer.provider 'OpenStreetMap.DE'
			CitraRiau: L.tileLayer.provider 'Esri.WorldImagery'
		overlays = {}

		source = _.map coll.fasilitas.find().fetch(), (i) ->
			i.kata = switch i.kondisi
				when 4 then 'Baik'
				when 3 then 'Rusak Ringan'
				when 2 then 'Rusak Sedang'
				when 1 then 'Rusak Berat'
				else 'n/a'
			i.warna = switch i.kondisi
				when 4 then 'green'
				when 3 then 'orange'
				when 2 then 'red'
				when 1 then 'darkred'
				else 'white'
			i

		makeLayers = (category, type, label, icon) ->
			markers = []
			for i in source
				if i.latlng and i[category] is type
					marker = L.marker i.latlng,
						icon: L.AwesomeMarkers.icon
							markerColor: i.warna
							prefix: 'fa'
							icon: icon
					content = '<b>Nama: </b>' + i.nama + '<br/>'
					content += '<b>Bentuk: </b>' + i.bentuk + '<br/>'
					content += '<b>Alamat: </b>' + i.alamat + '<br/>'
					content += '<b>Kondisi: </b>' + i.kata + '<br/>'
					for j in [1..5]
						if i['data'+j]
							content += '<b>'+headings[currentRoute()][j+3]+': </b>'+i['data'+j]+'<br/>'
					marker.bindPopup content
					markers.push marker
			overlays[label] = L.layerGroup markers

		uniqs = _.uniqBy coll.fasilitas.find().fetch(), 'bentuk'
		makeLayers 'bentuk', i.bentuk, i.bentuk, '' for i in uniqs
		kondisis = 1: 'Rusak Berat', 2: 'Rusak Sedang', 3: 'Rusak Ringan', 4: 'Baik'
		makeLayers 'kondisi', parseInt(val), name, '' for val, name of kondisis

		defaultLayers = [baseMaps.Topografi]
		for key, val of overlays
			defaultLayers.push overlays[key]

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			minZoom: 8
			maxZoom: 17
			zoomControl: false
			layers: defaultLayers

		layersControl = L.control.layers baseMaps, overlays, collapsed: false
		layersControl.addTo map
		locate = L.control.locate position: 'bottomright'
		locate.addTo map
		$('.num#1').parent().addClass 'active'
		Session.set 'limit', 200

	Template.fasilitas.helpers
		colHeadings: (name) -> headings[name]
		datas: ->
			if searchTerm()
				selector = nama: $regex: '.*'+searchTerm()+'.*', $options: 'i'
				options = {}
			else
				pagin = Session.get 'pagin'; limit = Session.get 'limit'
				selector = {}
				options = limit: limit, skip: pagin * limit
			coll.fasilitas.find(selector, options).fetch()

		stats: ->
			source = coll.fasilitas.find().fetch()
			jumlah = source.length
			kondisi =
				baik: (_.filter source, (i) -> i.kondisi is 4).length
				ringan: (_.filter source, (i) -> i.kondisi is 3).length
				sedang: (_.filter source, (i) -> i.kondisi is 2).length
				berat: (_.filter source, (i) -> i.kondisi is 1).length
			titik = (_.filter source, (i) -> i.latlng).length
			list = [
				title: 'Jumlah ' + _.startCase currentRoute()
				content: jumlah + ' unit'
				color: 'red'
				icon: 'account_balance'
			,
				title: 'Kondisi ' + _.startCase currentRoute()
				content: '
					Baik '+kondisi.baik+' unit <br/>
					Rusak Ringan '+kondisi.ringan+' unit <br/>
					Rusak Sedang '+kondisi.sedang+' unit <br/>
					Rusak Berat '+kondisi.berat+' unit <br/>
				'
				color: 'blue'
				icon: 'thumbs_up_down'
			,
				title: 'Jumlah Koordinat'
				content: titik + ' titik'
				color: 'green'
				icon: 'place'
			]

		kataKondisi: (num) ->
			switch num
				when 4 then 'Baik'
				when 3 then 'Rusak Ringan'
				when 2 then 'Rusak Sedang'
				when 1 then 'Rusak Berat'
				else 'n/a'

	Template.fasilitas.events
		'click #empty': ->
			dialog =
				message: 'Yakin Kosongkan Seluruh Sekolah?'
				title: 'Kosongkan DB Sekolah'
				okText: 'Ya'
				focus: 'cancel'
				success: true
			new Confirmation dialog, (ok) ->
				selector = kelompok: currentRoute()
				if ok then Meteor.call 'empty', 'fasilitas', selector
		'change :file': (event) ->
			Papa.parse event.target.files[0],
				header: true
				step: (row) ->
					record = row.data[0]
					record.kelompok = currentRoute()
					Meteor.call 'import', 'fasilitas', record.nama, record
		'click #geocode': ->
			getLatLng = (obj) ->
				geocode.getLocation obj.alamat + ' Riau', (location) ->
					obj.latlng = location.results[0].geometry.location
					Meteor.call 'update', 'fasilitas', obj
			for i in _.shuffle coll.fasilitas.find().fetch()
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
			zoomControl: false
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
		style = (feature) ->
			color: '#'+Math.random().toString(16).substr(-6)
			weight: 3
			dashArray: '3'
		onEachFeature = (feature, layer) ->
			layer.on
				mouseover: (event) ->
					event.target.setStyle
						weight: 8
						color: 'white'
						dashArray: ''
					event.target.bringToFront()
				mouseout: (event) ->
					jalan.resetStyle event.target
				click: (event) ->
					map.fitBounds event.target.getBounds()
			props = ['STATUS', 'NO', 'NO_RUAS', 'NAMA_RUAS', 'PJG_SURVEY', 'KECAMATAN', 'KELAS_JALA', 'Length']
			content = ''
			for i in props
				content += '<b>'+i+': </b>'+feature.properties[i]+'<br/>'
			layer.bindPopup content

		layers = _.map ['prov', 'nas'], (i) ->
			L.geoJson.ajax 'maps/jalan_'+i+'.geojson', style: style, onEachFeature: onEachFeature

		baseMaps =
			Citra: L.tileLayer.provider 'Esri.WorldImagery'
			WMS: L.tileLayer.wms 'https://demo.boundlessgeo.com/geoserver/ows?', layers: 'ne:ne'
		overlays =
			'Jalan Provinsi': layers[0]
			'Jalan Nasional': layers[1]

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			zoomControl: false
			layers: [baseMaps.Citra, layers...]

		layersControl = L.control.layers baseMaps, overlays, collapsed: false
		layersControl.addTo map

	Template.jalan.helpers
		jalan: -> coll.jalan.find().fetch()

	Template.jalan.events
		'change #upload': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					selector =
						status: data.status
						nama_ruas: data.nama_ruas
					modifier =
						no: parseInt data.no
						no_ruas: data.no_ruas
						tanggal: data.tanggal
						pjg_survey: data.pjg_survey
						kecamatan: data.kecamatan
						kelas_jala: data.kelas_jala
						length: data.length
					Meteor.call 'import', 'jalan', selector, modifier
		'click #empty': ->
			dialog =
				message: 'Yakin kosongkan Tabel Jalan?'
				title: 'Kosongkan Tabel'
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'empty', 'jalan', {}
		'click #openjalan': ->
			$('#tablejalan').removeClass 'hide'
			$('#openjalan').addClass 'hide'

	Template.ind.helpers
		datas: ->
			selector = grup: currentRoute()
			coll.ind.find(selector).fetch()
		title: ->
			find = _.find inds, (i) -> i.name is currentRoute()
			find.full
		list: ->
			switch currentRoute()
				when 'isd' then ['fokus', 'indikator']
				when 'ikd' then ['aspek', 'fokus', 'bidang', 'indikator', 'sub']
				when 'targ' then ['indikator', 'sub']
				when 'makro' then ['indikator', 'sub']
		years: -> [2013..2019]

	Template.ind.events
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					selector =
						sasaran: data.sasaran
						indikator: data.indikator
					modifier = {}
					for i in [2013..2019]
						modifier['y'+i] = tar: data['tar'+i], rel: data['rel'+i]
					Meteor.call 'import', 'ind', selector, _.assign modifier, grup: currentRoute()
