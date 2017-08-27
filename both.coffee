Router.configure
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/']
Router.route '/riau', action: -> this.render 'wil'
Router.route '/jalan',
	action: -> this.render 'jalan'
	waitOn: -> Meteor.subscribe 'jalans'

makeRoute = (name) ->
	Router.route '/' + name,
		action: -> this.render name
		waitOn: -> Meteor.subscribe 'coll', name

makeRoute i for i in ['sekolahs', 'ikd']

makeWil = (route) ->
	Router.route '/' + route,
		action: -> this.render 'wil'

makeWil i for i in [kels..., kecs..., kabs...]

coll.elemens = new Meteor.Collection 'elemens'
coll.elemens.attachSchema new SimpleSchema
	kab: type: String, autoform: type: 'hidden'
	kec: type: String, autoform: type: 'hidden'
	kel: type: String, autoform: type: 'hidden'
	elemen: type: String, autoform: type: 'hidden'
	indikator: type: String, autoform: disabled: true
	defenisi: type: String, optional: true, autoform: disabled: true
	satuan: type: String, optional: true
	y2015: type: Object, optional: true
	'y2015.tar': type: Number, decimal: true
	'y2015.rel': type: Number, decimal: true
	y2016: type: Object, optional: true
	'y2016.tar': type: Number, decimal: true
	'y2016.rel': type: Number, decimal: true
	y2017: type: Object, optional: true
	'y2017.tar': type: Number, decimal: true
	'y2017.rel': type: Number, decimal: true
	y2018: type: Object, optional: true
	'y2018.tar': type: Number, decimal: true
	'y2018.rel': type: Number, decimal: true
	y2019: type: Object, optional: true
	'y2019.tar': type: Number, decimal: true
	'y2019.rel': type: Number, decimal: true
coll.elemens.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.sekolahs = new Meteor.Collection 'sekolahs'
coll.sekolahs.attachSchema new SimpleSchema
	nama: type: String
	status: type: String
	bentuk: type: String
	alamat: type: String
	keldes: type: String
	siswa: type: Number
	latlng: type: Object, optional: true
	'latlng.lat': type: Number, decimal: true
	'latlng.lng': type: Number, decimal: true
coll.sekolahs.allow
	insert: -> true
	update: -> true
	remove: -> true

coll.wilStat = new Meteor.Collection 'wilStat'
coll.wilStat.attachSchema new SimpleSchema
	kab: type: String
	kec: type: String
	kel: type: String
	elemen: type: String
	sum: type: Number, decimal: true
	count: type: Number
	avg: type: Number, decimal: true
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
coll.ikd.attachSchema new SimpleSchema
	misi: type: String
	sasaran: type: String
	indikator: type: String
	y2013: type: Object, optional: true
	'y2013.tar': type: String, optional: true
	'y2013.rel': type: String, optional: true
	y2014: type: Object, optional: true
	'y2014.tar': type: String, optional: true
	'y2014.rel': type: String, optional: true
	y2015: type: Object, optional: true
	'y2015.tar': type: String, optional: true
	'y2015.rel': type: String, optional: true
	y2016: type: Object, optional: true
	'y2016.tar': type: String, optional: true
	'y2016.rel': type: String, optional: true
	y2017: type: Object, optional: true
	'y2017.tar': type: String, optional: true
	'y2017.rel': type: String, optional: true
	y2018: type: Object, optional: true
	'y2018.tar': type: String, optional: true
	'y2018.rel': type: String, optional: true
	y2019: type: Object, optional: true
	'y2019.tar': type: String, optional: true
	'y2019.rel': type: String, optional: true
coll.ikd.allow
	insert: -> true
	update: -> true
	remove: -> true
