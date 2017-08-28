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
			indikators = (elem) -> _.map coll.elemens.find({elemen: elem}).fetch(), (i) ->
				indikator: i.indikator
				tar2015: i.y2015.tar
			sumChild = (kab, kec, elem, ind, year) ->
				sum = 0
				for i in coll.elemens.find({kab: kab, kec: kec, indikator: ind}).fetch()
					sum += i[year].rel
				sum
			for i in kecs
				kab = i.split('_')[0]
				kec = i.split('_')[1]
				for j in elemens
					if 0 < _.size indikators j
						for k in indikators j
							data =
								kab: kab
								kec: kec
								kel: '*'
								elemen: j
								indikator: k.indikator
								y2015:
									tar: k.tar2015
									rel: sumChild kab, kec, j, k.indikator, 'y2015'
							if data.y2015.rel > 0
								console.log data, ++num

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
