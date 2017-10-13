Router.configure
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/']
Router.route '/riau', action: -> this.render 'wil'

makeInd = (name) ->
	Router.route '/' + name,
		action: -> this.render 'ind'
		waitOn: -> Meteor.subscribe 'coll', 'ind', {}, {}
makeInd i.name for i in inds

Router.route '/jalan',
	action: -> this.render 'jalan'
	waitOn: -> Meteor.subscribe 'coll', 'jalan', {}, {}

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
makeFasil key for key, val of headings

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
	alamat: type: String
	bentuk: type: String
	kondisi: type: Number, decimal: true, optional: true, autoform: options: selects.kondisi
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

coll.jalan = new Meteor.Collection 'jalan'
coll.jalan.attachSchema new SimpleSchema
	status: type: String
	no: type: Number, optional: true
	tanggal: type: String, optional: true
	no_ruas: type: String, optional: true
	nama_ruas: type: String, optional: true
	pjg_survey: type: Number, decimal: true, optional: true
	kecamatan: type: String, optional: true
	kelas_jala: type: String, optional: true
	length: type: Number, decimal: true, optional: true
coll.jalan.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.ind = new Meteor.Collection 'ind'
objek =
	grup: type: String
	sasaran: type: String
	indikator: type: String
for i in years 2013, 2019
	objek[i] = type: Object, optional: true
	objek[i+'.tar'] = type: String, optional: true
	objek[i+'.rel'] = type: String, optional: true
	coll.ind.attachSchema new SimpleSchema objek
coll.ind.allow
	insert: -> true
	update: -> true
	remove: -> true
