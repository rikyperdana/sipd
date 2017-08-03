if Meteor.isClient

	AutoForm.setDefaultTemplate 'materialize'
	currentRoute = -> Router.current().route.getName()
	wilName = ->
		kab: currentRoute().split('_')[0]
		kec: currentRoute().split('_')[1]
		kel: currentRoute().split('_')[2]

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

	Template.layout.onRendered ->
		Session.set 'pagin', 0

	Template.kel.helpers
		datas: ->
			selectElemen = Session.get 'selectElemen'
			searchTerm = Session.get 'searchTerm'
			source = coll.elemens.find().fetch()
			if searchTerm
				_.filter source, (i) -> i.indikator.toLowerCase().includes searchTerm
			else if selectElemen
				_.filter source, (i) -> i.elemen is selectElemen
			else
				source

	Template.kel.events
		'click #emptyElemen': ->
			dialog =
				message: 'Yakin kosongkan elemen?'
				title: 'Elemen ' + Session.get 'selectElemen'
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'emptyElemen', currentRoute(), Session.get 'selectElemen'
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					data = result.data[0]
					pecah = data.indikator.split ' '
					buang = _.reject pecah, (i) -> i.includes ')'
					data.indikator = buang.join ' '
					Meteor.call 'import', 'elemens',
						kab: wilName().kab
						kec: wilName().kec
						kel: wilName().kel
						elemen: _.kebabCase data.elemen
						indikator: data.indikator
						defenisi: data.defenisi
						nilai: data.nilai


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
			barArray.push [i.elemen, i.nilai] for i in coll.elemens.find().fetch()
			data: type: 'bar', columns: barArray

	Template.map.onRendered ->
		sumEl = ->
			source = coll.elemens.find().fetch()
			selectElemen = Session.get 'selectElemen'
			sum = 0
			filter = _.filter source, (i) ->
				i.elemen is selectElemen
			for i in filter
				sum += i.nilai
			if sum < 10000
				'red'
			else
				'blue'

		getColor = (prop) ->
			selectElemen = Session.get 'selectElemen'
			if wilName().kel
				if _.kebabCase(prop.DESA) is wilName().kel then sumEl()
			else if wilName().kec
				if _.kebabCase(prop.KECAMATAN) is wilName().kec then 'orange'
		getOpac = (prop) ->
			if wilName().kel
				if _.kebabCase(prop.DESA) isnt wilName().kel then 0 else 0.7
			else if wilName().kec
				if _.kebabCase(prop.KECAMATAN) isnt wilName().kec then 0 else 0.7
		style = (feature) ->
			opacity: 0
			fillColor: getColor feature.properties
			fillOpacity: getOpac feature.properties

		topo = L.tileLayer.provider 'OpenTopoMap'
		geojson = L.geoJson.ajax 'maps/petas.geojson',
			style: style

		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			zoomControl: false
			layers: [topo, geojson]

	Template.kec.helpers
		datas: ->
			selectElemen = Session.get 'selectElemen'
			list = []
			for i in coll.elemens.find().fetch()
				find = _.find list, (j) -> j.indikator is i.indikator
				if find
					find.nilai += i.nilai
				else
					list.push i

			if selectElemen
				_.filter list, (i) -> i.elemen is selectElemen
			else
				list

	Template.sekolahs.onRendered ->
		baseMaps =
			Topografi: L.tileLayer.provider 'OpenTopoMap'
			Jalan: L.tileLayer.provider 'OpenStreetMap.DE'
			CitraRiau: L.tileLayer.provider 'Esri.WorldImagery'
		overlays = {}

		makeLayers = (category, type, color) ->
			markers = []
			for i in coll.sekolahs.find().fetch()
				if i.latlng and i[category] is type
					marker = L.marker i.latlng,
						icon: L.AwesomeMarkers.icon
							markerColor: color
							prefix: 'fa'
							icon: 'graduation-cap'
					content = '<b>Nama: </b>' + i.nama + '<br/>'
					content += '<b>Bentuk: </b>' + i.bentuk + '<br/>'
					content += '<b>Alamat: </b>' + i.alamat + ' ' + i.keldes + '<br/>'
					content += '<b>Siswa: </b>' + i.siswa + ' orang <br/>'
					marker.bindPopup content
					markers.push marker
			overlays[type] = L.layerGroup markers

		makeLayers 'bentuk', 'SD', 'orange'
		makeLayers 'bentuk', 'SMP', 'red'
		makeLayers 'bentuk', 'SMA', 'darkred'
		makeLayers 'bentuk', 'SMK', 'darkgreen'

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
			searchTerm = Session.get 'searchTerm'
			if searchTerm
				_.filter coll.sekolahs.find().fetch(), (i) ->
					asNama = i.nama.toLowerCase().includes searchTerm
					asAlamat = i.alamat.toLowerCase().includes searchTerm
					asKeldes = i.keldes.toLowerCase().includes searchTerm
					true if asNama or asAlamat or asKeldes
			else
				pagin = Session.get 'pagin'
				limit = Session.get 'limit'
				selector = {}
				options =
					limit: limit
					skip: pagin * limit
				coll.sekolahs.find(selector, options).fetch()
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
