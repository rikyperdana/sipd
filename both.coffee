Router.configure
	layoutTemplate: 'layout'

Router.route '/',
	action: -> this.render 'home'

makeKel = (name) ->
	Router.route '/' + name,
		action: -> this.render 'kel'
		waitOn: -> Meteor.subscribe 'elemens', name

makeKel i for i in kels

coll.elemens = new Meteor.Collection 'elemens'
coll.elemens.attachSchema new SimpleSchema
	kab: type: String
	kec: type: String
	kel: type: String
	elemen: type: String, optional: true
	indikator: type: String, optional: true
	defenisi: type: String, optional: true
	nilai: type: Number, decimal: true, optional: true
	satuan: type: String, optional: true
	setuju: type: Boolean, optional: true
	beda: type: String, optional: true
	justifikasi: type: String, optional: true
coll.elemens.allow
	insert: -> true
	update: -> true
	remove: -> true
