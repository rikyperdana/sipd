if Meteor.isClient

	AutoForm.setDefaultTemplate 'materialize'
	currentRoute = (cb) -> cb Router.current().route.getName()

	Template.importer.events
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
						defenisi: data.indikator
						nilai: data.nilai

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
		theColl: -> coll.elemens
		editData: -> Session.get 'editData'

	Template.kel.events
		'dblclick #row': (satu, dua) ->
			Session.set 'editData', this
		'click #close': ->
			Session.set 'editData', null

	Template.selectElemen.onRendered ->
		$('select').material_select()

	Template.selectElemen.helpers
		elemensName: -> _.map elemens, (i) -> _.startCase i

	Template.selectElemen.events
		'change select': (event) ->
			Session.set 'selectElemen', _.kebabCase event.target.value
		'keyup #search': (event) ->
			Session.set 'searchTerm', event.target.value.toLowerCase()
