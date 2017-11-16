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
	range = -> switch currentRoute()
		when 'makro' then [2010..2016]
		else [2014..2019]

	Template.registerHelper 'coll', -> coll
	Template.registerHelper 'currentRoute', -> currentRoute()
	Template.registerHelper 'routeIs', (name) -> currentRoute() is name
	Template.registerHelper 'routeIn', (arr) -> _.find arr, (i) -> i is currentRoute()
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

	Template.grafik.helpers
		grafik: ->
			barArray = []
			rowGraph = Session.get 'rowGraph'
			xAxis = ['x']
			tars = ['Target']
			rels = ['Realisasi']
			for i in range()
				xAxis.push i.toString()+'-01-01'
				tars.push parseInt rowGraph['y'+i].tar
				rels.push parseInt rowGraph['y'+i].rel
			barArray.push xAxis, tars, rels
			doc =
				data:
					x: 'x'
					type: 'bar'
					columns: barArray
				axis: x:
					type: 'timeseries'
					tick: format: '%Y'

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
					jalNas.resetStyle event.target
					jalProv.resetStyle event.target
				click: (event) ->
					map.fitBounds event.target.getBounds()
			props = ['STATUS', 'NO', 'NO_RUAS', 'NAMA_RUAS', 'PJG_SURVEY', 'KECAMATAN', 'KELAS_JALA', 'Length']
			content = ''
			for i in props
				content += '<b>'+i+': </b>'+feature.properties[i]+'<br/>'
			layer.bindPopup content

		jalNas = L.geoJson.ajax 'maps/jalan_nas.geojson', style: style, onEachFeature: onEachFeature
		jalProv = L.geoJson.ajax 'maps/jalan_prov.geojson', style: style, onEachFeature: onEachFeature

		baseMaps =
			Citra: L.tileLayer.provider 'Esri.WorldImagery'
			WMS: L.tileLayer.wms 'https://demo.boundlessgeo.com/geoserver/ows?', layers: 'ne:ne'
		overlays =
			'Jalan Provinsi': jalProv
			'Jalan Nasional': jalNas

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			zoomControl: false
			layers: [baseMaps.Citra, jalNas, jalProv]

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
		kabs: -> kabs
		datas: ->
			find = _.find kabs, (i) -> i is currentRoute()
			selector = grup: if find then 'targ' else currentRoute()
			if find then selector.sub = _.startCase Session.get 'selKab'
			coll.ind.find(selector).fetch()
		title: ->
			find = _.find inds, (i) -> i.name is currentRoute()
			find.full
		list: ->
			find = _.find kabs, (i) -> i is currentRoute()
			switch currentRoute()
				when 'isd' then ['fokus', 'indikator']
				when 'ikd' then ['aspek', 'fokus', 'bidang', 'indikator', 'sub']
				when find then ['indikator', 'sub']
				when 'makro' then ['indikator', 'sub']
		years: -> range()

	Template.ind.events
		'click #rowGraph': ->
			Session.set 'rowGraph', this
		'click #empty': (event) ->
			param = event.target.attributes.param.nodeValue
			dialog =
				message: 'Anda yakin hapus data?'
				title: 'Konfirmasi Hapus'
			new Confirmation dialog, (ok) ->
				find = _.find kabs, (i) -> i is currentRoute()
				grup = if find then 'targ' else currentRoute()
				if ok then Meteor.call 'empty', 'ind', grup: grup
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					selector =
						aspek: data.aspek
						fokus: data.fokus
						bidang: data.bidang
						indikator: data.indikator
						sub: data.sub
					modifier = {}
					for i in range()
						modifier['y'+i] = tar: data['tar'+i], rel: data['rel'+i]
					grup = ->
						find = _.find kabs, (i) -> i is currentRoute()
						if find then 'targ' else currentRoute()
					Meteor.call 'import', 'ind', selector, _.assign modifier, grup: grup()

	Template.tem.onRendered ->
		state = (wil) ->
			mapColor = Session.get 'mapColor'
			find = _.find mapColor, (i) -> i.kab is wil
			year = 2014
			if find
				if find['col' + year]
					find['col' + year]
				else
					'white'
		style = (feature) ->
			fillColor: state feature.properties.wil
			fillOpacity: 1
			opacity: 0
		topo = L.tileLayer.provider 'OpenTopoMap'
		riau = L.geoJson.ajax '/maps/riau.geojson', style: style
		map = L.map 'map',
			center: [0.5, 102]
			zoom: 8
			layers: [topo, riau]

	Template.tem.helpers
		datas: ->
			splited = currentRoute().split('.')
			find = (name) -> _.find coll.tem.find().fetch(), (i) ->
				a = -> i.kab is name
				b = -> i.grup is splited[0]
				c = -> i.item is splited[1]
				a() and b() and c()
			prov = find 'riau'; nas = find 'nasional'
			kabs = _.filter coll.tem.find().fetch(), (i) ->
				a = -> i.grup is splited[0]
				b = -> i.item is splited[1]
				c = -> i.kab isnt 'riau'
				d = -> i.kab isnt 'nasional'
				a() and b() and c() and d()
			list = _.map kabs, (i) ->
				for j in [2014..2019]
					if nas['y'+j] > i['y'+j] < prov['y'+j]
						i['col'+j] = 'red'
					else if nas['y'+j] > i['y'+j] > prov['y'+j]
						i['col'+j] = 'orange'
					else if nas['y'+j] < i['y'+j] < prov['y'+j]
						i['col'+j] = 'green'
					else if nas['y'+j] < i['y'+j] > prov['y'+j]
						i['col'+j] = 'blue'
				i
			Session.set 'mapColor', list
			list

	Template.tem.events
		'click #col': (event) ->
			Session.set 'selYear', parseInt event.target.textContent
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					selector =
						kab: data.kab
						grup: data.grup
						item: data.item
					modifier = {}
					for i in [2014..2019]
						modifier['y' + i] = parseFloat data['y' + i]
					Meteor.call 'import', 'tem', selector, modifier
