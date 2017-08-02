if Meteor.isClient

	AutoForm.setDefaultTemplate 'materialize'
	currentRoute = (cb) -> cb Router.current().route.getName()

	Template.registerHelper 'coll', -> coll
	Template.registerHelper 'showContoh', -> Session.get 'showContoh'
	Template.registerHelper 'showGraph', -> Session.get 'showGraph'
	Template.registerHelper 'showMap', -> Session.get 'showMap'
	Template.registerHelper 'showAdd', -> Session.get 'showAdd'
	Template.registerHelper 'pageTitle', ->
		route = currentRoute (res) -> res
		kab = _.startCase route.split('_')[0]
		kec = _.startCase route.split('_')[1]
		kel = _.startCase route.split('_')[2]
		kab: kab, kec: kec, kel: kel
	Template.registerHelper 'editData', -> Session.get 'editData'

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
			route = currentRoute (res) -> res
			dialog =
				message: 'Yakin kosongkan elemen?'
				title: 'Elemen ' + Session.get 'selectElemen'
				okText: 'Ya'
				success: true
				focus: 'cancel'
			new Confirmation dialog, (ok) ->
				if ok then Meteor.call 'emptyElemen', route, Session.get 'selectElemen'
		'change :file': (event, template) ->
			Papa.parse event.target.files[0],
				header: true
				step: (result) ->
					route = currentRoute (res) -> res
					data = result.data[0]
					pecah = data.indikator.split ' '
					buang = _.reject pecah, (i) -> i.includes ')'
					data.indikator = buang.join ' '
					Meteor.call 'import', 'elemens',
						kab: route.split('_')[0]
						kec: route.split('_')[1]
						kel: route.split('_')[2]
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
		'keyup #search': (event) ->
			Session.set 'searchTerm', event.target.value.toLowerCase()

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
		route = currentRoute (res) -> res
		kab = route.split('_')[0]
		kec = route.split('_')[1]
		kel = route.split('_')[2]

		sumEl = (route, elemen) ->
			source = coll.elemens.find().fetch()
			selectElemen = Session.get 'selectElemen'
			sum = 0
			filter = _.filter source, (i) ->
				i.elemen is selectElemen
			for i in filter
				sum += i.nilai
			console.log sum, filter
			if sum < 10000
				'red'
			else
				'blue'

		getColor = (prop) ->
			route = currentRoute (res) -> res
			selectElemen = Session.get 'selectElemen'
			kab = route.split('_')[0]
			kec = route.split('_')[1]
			kel = route.split('_')[2]
			if kel
				if _.kebabCase(prop.DESA) is kel then sumEl route, selectElemen
			else if kec
				if _.kebabCase(prop.KECAMATAN) is kec then 'orange'
		getOpac = (prop) ->
			route = currentRoute (res) -> res
			kab = route.split('_')[0]
			kec = route.split('_')[1]
			kel = route.split('_')[2]
			if kel
				if _.kebabCase(prop.DESA) isnt kel then 0 else 0.7
			else if kec
				if _.kebabCase(prop.KECAMATAN) isnt kec then 0 else 0.7
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
			'Topografi': L.tileLayer.provider 'OpenTopoMap'
			'Jalan': L.tileLayer.provider 'OpenStreetMap.DE'
		overlays = {}

		makeLayers = (type, color) ->
			markers = []
			for i in coll.sekolahs.find().fetch()
				if i.latlng
					if i.bentuk is type
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

		makeLayers 'SD', 'orange'
		makeLayers 'SMP', 'red'
		makeLayers 'SMA', 'darkred'
		makeLayers 'SMK', 'darkgreen'

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


	Template.sekolahs.helpers
		datas: -> coll.sekolahs.find().fetch()

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
			for i in coll.sekolahs.find().fetch().reverse()
				unless i.latlng then getLatLng i
