Router.configure
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/login']

makeInd = (name, sel) ->
	Router.route '/' + name,
		action: ->
			this.render 'ind'
			if Meteor.isClient
				cur = Router.current().route.getName()
				find = _.find kabs, (i) -> i is cur
				if find then Session.set 'selKab', cur
		waitOn: -> if Meteor.isClient
			Meteor.subscribe 'coll', 'ind', {grup: sel}, {}
makeInd i.name, i.name for i in inds
makeInd i, 'targ' for i in kabs

Router.route '/jalan',
	action: -> this.render 'jalan'
	waitOn: -> Meteor.subscribe 'coll', 'jalan', {}, {}

makeFasil = (name) ->
	Router.route '/' + name,
		action: -> this.render 'fasilitas'
		waitOn: ->
			selector = kelompok: name
			options = {}
			Meteor.subscribe 'coll', 'fasilitas', selector, options
makeFasil key for key, val of headings

years = (start, end) -> _.map [start..end], (i) -> 'y' + i

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
	grup: type: String, optional: true
	aspek: type: String, optional: true
	fokus: type: String, optional: true
	bidang: type: String, optional: true
	indikator: type: String, optional: true
	sub: type: String, optional: true
for i in years 2013, 2019
	objek[i] = type: Object, optional: true
	objek[i+'.tar'] = type: String, optional: true
	objek[i+'.rel'] = type: String, optional: true
	coll.ind.attachSchema new SimpleSchema objek
coll.ind.allow
	insert: -> true
	update: -> true
	remove: -> true
