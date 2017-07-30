Router.configure
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/']

makeWil = (route) ->
	Router.route '/' + route,
		action: ->
			if route.split('_').length is 3
				this.render 'kel'
			else
				this.render 'kec'
		waitOn: -> Meteor.subscribe 'elemens', route

makeWil i for i in kels
makeWil i for i in kecs

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
