if Meteor.isServer

	Meteor.publish 'elemens', (wils, elemen) ->
		selector = kab: wils.kab, kec: wils.kec, kel: wils.kel
		if elemen then selector.elemen = elemen
		coll.elemens.find selector

	Meteor.publish 'sekolahs', ->
		coll.sekolahs.find {}

	Meteor.methods
		import: (collName, data) ->
			coll[collName].insert data
		emptyElemen: (wils, elemen) ->
			selector = {}
			if wils.kab then selector.kab = wils.kab else selector.kab = '*'
			if wils.kec then selector.kec = wils.kec else selector.kec = '*'
			if wils.kel then selector.kel = wils.kel else selector.kel = '*'
			selector.elemen = elemen
			coll.elemens.remove selector
		emptySekolahs: ->
			coll.sekolahs.remove {}
		emptyJalProv: ->
			coll.jalProv.remove {}
		emptyJalNas: ->
			coll.jalNas.remove {}
		emptyColl: (name) ->
			coll[name].remove {}
		updateSekolah: (obj) ->
			coll.sekolahs.update obj._id, $set: obj

		wilSum: ->
			num = 0
			aggKec = []
			for i in coll.elemens.find({kel: {$ne: '*'}}).fetch()
				findKec = _.find aggKec, (j) ->
					kab = j.kab is i.kab
					kec = j.kec is i.kec
					elemen = j.elemen is i.elemen
					indikator = j.indikator is i.indikator
					kab and kec and elemen and indikator
				if findKec
					delete findKec._id
					findKec.kel = '*'
					findKec.y2015.rel += i.y2015.rel
				else
					aggKec.push i
			for i in aggKec
				selector =
					kab: i.kab
					kec: i.kec
					kel: '*'
					elemen: i.elemen
					indikator: i.indikator
				modifier =
					y2015: i.y2015
				coll.elemens.upsert selector, $set: modifier


			aggKab = []
			for i in coll.elemens.find({kec: {$ne: '*'}, kel: '*'}).fetch()
				findKab = _.find aggKab, (j) ->
					kab = j.kab is i.kab
					elemen = j.elemen is i.elemen
					indikator = j.indikator is i.indikator
					kab and elemen and indikator
				if findKab
					delete findKab._id
					findKab.kel = '*'
					findKab.y2015.rel += i.y2015.rel
				else
					aggKab.push i
			for i in aggKab
				selector =
					kab: i.kab
					kec: '*'
					kel: '*'
					elemen: i.elemen
					indikator: i.indikator
				modifier =
					y2015: i.y2015
				coll.elemens.upsert selector, $set: modifier


			aggProv = []
			for i in coll.elemens.find({kec: {$ne: '*'}, kel: '*'}).fetch()
				findProv = _.find aggProv, (j) ->
					elemen = j.elemen is i.elemen
					indikator = j.indikator is i.indikator
					elemen and indikator
				if findKab
					delete findProv._id
					findProv.kel = '*'
					findProv.y2015.rel += i.y2015.rel
				else
					aggProv.push i
			for i in aggProv
				selector =
					kab: '*'
					kec: '*'
					kel: '*'
					elemen: i.elemen
					indikator: i.indikator
				modifier =
					y2015: i.y2015
				coll.elemens.upsert selector, $set: modifier

			

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
				modifier =
					$set:	
						sum: i.sum
						count: i.count
						avg: i.avg
				coll.wilStat.upsert selector, modifier

		Meteor.publish 'wilStat', (wilName, elemen) ->
			selector = {}
			if wilName.kab is 'riau'
				selector = {}
			else
				if wilName.kab then selector.kab = wilName.kab
				if wilName.kec then selector.kec = wilName.kec
				if wilName.kel then selector.kel = wilName.kel
				if elemen then selector.elemen = elemen
			coll.wilStat.find selector

		Meteor.publish 'jalans', ->
			[
				coll.jalProv.find {}
				coll.jalNas.find {}
			]

		Meteor.publish 'coll', (name, sel, opt) ->
			selector = {}
			options = {}
			coll[name].find selector, options
