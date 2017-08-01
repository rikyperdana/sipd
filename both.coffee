Router.configure
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/']

makeRoute = (route) ->
	Router.route '/' + route,
		action: ->
			if route.split('_').length is 3
				this.render 'kel'
			else
				this.render 'kec'
		waitOn: -> Meteor.subscribe 'elemens', route

makeRoute i for i in kels
makeRoute i for i in kecs

Router.route '/sekolahs',
	action: -> this.render 'sekolahs'
	waitOn: -> Meteor.subscribe 'sekolahs'

coll.elemens = new Meteor.Collection 'elemens'
coll.elemens.attachSchema new SimpleSchema
	kab: type: String, autoform: type: 'hidden'
	kec: type: String, autoform: type: 'hidden'
	kel: type: String, autoform: type: 'hidden'
	elemen: type: String, autoform: type: 'hidden'
	indikator: type: String, autoform: disabled: true
	defenisi: type: String, optional: true, autoform: disabled: true
	nilai: type: Number, decimal: true, optional: true
	satuan: type: String, optional: true, autoform: disabled: true
	setuju: type: Boolean, optional: true
	beda: type: String, optional: true
	justifikasi: type: String, optional: true
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
	latlng: type: Object, optional: true, autoform: type: 'hidden'
	'latlng.lat': type: Number, decimal: true
	'latlng.lng': type: Number, decimal: true
coll.sekolahs.allow
	insert: -> true
	update: -> true
	remove: -> true
