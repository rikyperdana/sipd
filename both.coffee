Router.configure
	layoutTemplate: 'layout'

Router.route '/', action: -> this.render 'home'
Router.route '/login', action: -> this.render 'login'
Router.route '/logout', action: -> [Meteor.logout(), Router.go '/']

makeKel = (name) ->
	Router.route '/' + name,
		action: -> this.render 'kel'
		waitOn: -> Meteor.subscribe 'elemens', name

makeKel i for i in kels

coll.elemens = new Meteor.Collection 'elemens'
coll.elemens.attachSchema new SimpleSchema
	kab: type: String, autoform: type: 'hidden'
	kec: type: String, autoform: type: 'hidden'
	kel: type: String, autoform: type: 'hidden'
	elemen: type: String, optional: true, autoform: type: 'hidden'
	indikator: type: String, optional: true, autoform: disabled: true
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
