if Meteor.isServer

	Meteor.publish 'elemens', (route) ->
		kab = route.split('_')[0]
		kec = route.split('_')[1]
		kel = route.split('_')[2]
		if kel
			coll.elemens.find kab: kab, kec: kec, kel: kel
		else if kec
			coll.elemens.find kab: kab, kec: kec
		else if kab
			coll.elemens.find kab: kab

	Meteor.publish 'sekolahs', ->
		coll.sekolahs.find {}

	Meteor.methods
		import: (collName, data) ->
			coll[collName].insert data
		emptyElemen: (route, elemen) ->
			coll.elemens.remove
				kab: route.split('_')[0]
				kec: route.split('_')[1]
				kel: route.split('_')[2]
				elemen: elemen
		emptySekolahs: ->
			coll.sekolahs.remove {}
