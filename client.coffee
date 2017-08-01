if Meteor.isClient

	AutoForm.setDefaultTemplate 'materialize'
	currentRoute = (cb) -> cb Router.current().route.getName()

	Template.registerHelper 'coll', -> coll
	Template.registerHelper 'showContoh', -> Session.get 'showContoh'
	Template.registerHelper 'showGraph', -> Session.get 'showGraph'
	Template.registerHelper 'showMap', -> Session.get 'showMap'
	Template.registerHelper 'pageTitle', ->
		route = currentRoute (res) -> res
		kab = _.startCase route.split('_')[0]
		kec = _.startCase route.split('_')[1]
		kel = _.startCase route.split('_')[2]
		kab: kab, kec: kec, kel: kel

	Template.body.events
		'click #showContoh': ->
			Session.set 'showContoh', not Session.get 'showContoh'
		'click #showGraph': ->
			Session.set 'showGraph', not Session.get 'showGraph'
		'click #showMap': ->
			Session.set 'showMap', not Session.get 'showMap'


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
		editData: -> Session.get 'editData'

	Template.kel.events
		'dblclick #row': (satu, dua) ->
			Session.set 'editData', this
		'click #close': ->
			Session.set 'editData', null
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

	Template.infras.onRendered ->
		topo = L.tileLayer.provider 'OpenTopoMap'
		map = L.map 'map',
			center: [0.5, 101.44]
			zoom: 8
			minZoom: 8
			maxZoom: 17
			zoomControl: false
			layers: [topo]

	Template.infras.helpers
		datas: -> coll.infras.find().fetch()

	Template.infras.events
		'click #empty': -> Meteor.call 'emptyInfras'
		'change :file': (event) ->
			Papa.parse event.target.files[0],
				header: true
				step: (row) ->
					record = row.data[0]
					getLatLng = (doc, cb) ->
						geocode.getLocation doc.alamat, (location) ->
							if location.results[0]
								doc.latlng = location.results[0].geometry.location
								cb doc
							else
								cb doc
					impor = (doc) ->
						obj =
							jenis: 'sekolah'
							nama: doc.nama
							status: doc.status
							bentuk: doc.bentuk
							alamat: doc.alamat
							keldes: doc.keldes
							jumlah: doc.siswa
						if doc.latlng
							obj.latlng = doc.latlng
						Meteor.call 'import', 'infras', obj
					getLatLng record, (res) -> impor res
