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

		Meteor.publish 'wilStat', (wilName, elemen) ->
			coll.wilStat.find
				kab: wilName.kab
				kec: wilName.kec
				kel: wilName.kel
				elemen: elemen

		wilStat: ->
			source = _.map coll.elemens.find().fetch(), (i) ->
				i.sum = 0
				i.count = 0
				i.avg = 0
				i
			list = []
			for i in source
				find = _.find list, (j) ->
					kab = j.kab is i.kab
					kec = j.kec is i.kec
					kel = j.kel is i.kel
					elemen = j.elemen is i.elemen
					true if kab and kec and kel and elemen
				if find
					find.count += 1
					find.sum += i.nilai
					find.avg = find.sum / find.count
				else
					list.push i
			for i in list
				selector =
					kab: i.kab
					kec: i.kec
					kel: i.kel
					elemen: i.elemen
				modifier = $set:	
					sum: i.sum
					count: i.count
					avg: i.avg
				coll.wilStat.upsert selector, modifier
