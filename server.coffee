if Meteor.isServer

	Meteor.publish 'elemens', (kab, kec, kel, elemen) ->
		selector = {}
		if kab then selector.kab = kab
		if kec then selector.kec = kec
		if kel then selector.kel = kel
		if elemen then selector.elemen = elemen
		coll.elemens.find selector

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
		updateSekolah: (obj) ->
			coll.sekolahs.update obj._id, $set: obj
		wilSum: (kab, kec, kel, elemen) ->
			source = coll.elemens.find().fetch()
			list = []
			for i in source
				find = _.find list, (j) -> j.indikator is i.indikator
				if find
					find.nilai += i.nilai
				else
					list.push i
			if elemen
				_.filter list, (i) -> i.elemen is elemen
			else
				list
