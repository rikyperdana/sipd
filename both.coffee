Router.configure
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/']
Router.route '/riau', action: -> this.render 'wil'
Router.route '/jalan',
	action: -> this.render 'jalan'
	waitOn: -> [
		Meteor.subscribe 'coll', 'jalProv', {}, {}
		Meteor.subscribe 'coll', 'jalNas', {}, {}
	]

makeWil = (route) ->
	Router.route '/' + route,
		action: -> this.render 'wil'

makeWil i for i in [kels..., kecs..., kabs...]

makeFasil = (name) ->
	Router.route '/' + name,
		action: -> this.render 'fasilitas'
		waitOn: ->
			selector = kelompok: name
			options = {}
			Meteor.subscribe 'coll', 'fasilitas', selector, options

makeFasil i for i in ['sekolah', 'pariwisata', 'kesehatan', 'industri', 'komunikasi', 'sosial', 'perhubungan', 'olahraga', 'kesenian', 'religi']

years = (start, end) -> _.map [start..end], (i) -> 'y' + i

coll.elemens = new Meteor.Collection 'elemens'
objek =
	kab: type: String, autoform: type: 'hidden'
	kec: type: String, autoform: type: 'hidden'
	kel: type: String, autoform: type: 'hidden'
	elemen: type: String, autoform: type: 'hidden'
	indikator: type: String, autoform: disabled: true
	defenisi: type: String, optional: true, autoform: disabled: true
	satuan: type: String, optional: true
for i in years 2015, 2019
	objek[i] = type: Object, optional: true
	objek[i+'.tar'] = type: Number, decimal: true
	objek[i+'.rel'] = type: Number, decimal: true
coll.elemens.attachSchema new SimpleSchema objek
coll.elemens.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.fasilitas = new Meteor.Collection 'fasilitas'
obj =
	kelompok: type: String
	nama: type: String
	kondisi: type: Number, decimal: true
	alamat: type: String
	bentuk: type: String
	nilai: type: String
	latlng: type: Object, optional: true
	'latlng.lat': type: Number, decimal: true
	'latlng.lng': type: Number, decimal: true
for i in [1..5]
	obj['data'+i] = type: String, optional: true
coll.fasilitas.attachSchema new SimpleSchema obj
coll.fasilitas.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.wilStat = new Meteor.Collection 'wilStat'
objek =
	kab: type: String
	kec: type: String
	kel: type: String
	elemen: type: String
	indikator: type: Number
for i in years 2015, 2019
	objek[i] = type: Object, optional: true
	objek[i+'.sumKin'] = type: Number, decimal: true
	objek[i+'.avgKin'] = type: Number, decimal: true
	coll.wilStat.attachSchema new SimpleSchema objek
coll.wilStat.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.jalProv = new Meteor.Collection 'jalProv'
coll.jalProv.attachSchema new SimpleSchema
	no_ruas: type: String, optional: true
	nama_ruas: type: String
	kab_kota: type: String, optional: true
	kec: type: String, optional: true
	tp_awal: type: String, optional: true
	tp_akhir: type: String, optional: true
	pjg_survey: type: Number, decimal: true, optional: true
	sts_jalan: type: String, optional: true
	no: type: Number, optional: true
	aadt: type: Number, decimal: true, optional: true
	lebar: type: Number, decimal: true, optional: true
	stype: type: String, optional: true
	iri: type: Number, decimal: true, optional: true
	sdi: type: Number, decimal: true, optional: true
	eirr: type: Number, decimal: true, optional: true
	y2016: type: Object, optional: true
	'y2016.lp': type: String, optional: true
	'y2016.cost': type: Number, decimal: true, optional: true
	'y2016.el': type: Number, decimal: true, optional: true
	y2017: type: Object, optional: true
	'y2017.lp': type: String, optional: true
	'y2017.cost': type: Number, decimal: true, optional: true
	'y2017.el': type: Number, decimal: true, optional: true
coll.jalProv.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.jalNas = new Meteor.Collection 'jalNas'
coll.jalNas.attachSchema new SimpleSchema
	status: type: String
	no: type: Number, optional: true
	tanggal: type: String, optional: true
	no_ruas: type: String, optional: true
	nama_ruas: type: String, optional: true
	pjg_survey: type: Number, decimal: true, optional: true
	kecamatan: type: String, optional: true
	kelas_jala: type: String, optional: true
	length: type: Number, decimal: true, optional: true
coll.jalNas.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.ikd = new Meteor.Collection 'ikd'
objek =
	misi: type: String
	sasaran: type: String
	indikator: type: String
for i in years 2013, 2019
	objek[i] = type: Object, optional: true
	objek[i+'.tar'] = type: Number, optional: true
	objek[i+'.rel'] = type: Number, optional: true
	coll.ikd.attachSchema new SimpleSchema objek
coll.ikd.allow
	insert: -> true
	update: -> true
	remove: -> true
