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
		imporUrusan: (selector, modifier) ->
			coll.elemens.upsert selector, $set: modifier
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
			sumit = (selector, isKab, isKec) ->
				# container array
				aggWil = []
				# sum array of childs indikators to obj parent indikator
				for i in coll.elemens.find(selector).fetch()
					findWil = _.find aggWil, (j) ->
						if isKab then kab = j.kab is i.kab
						if isKec then kec = j.kec is i.kec
						elemen = j.elemen is i.elemen
						indikator = j.indikator is i.indikator
						if isKab and isKec
							kab and kec and elemen and indikator
						else if isKab
							kab and elemen and indikator
						else
							elemen and indikator
					if findWil
						delete findWil._id
						findWil.y2015.rel += i.y2015.rel
						findWil.y2016.rel += i.y2016.rel
						findWil.y2017.rel += i.y2017.rel
						findWil.y2018.rel += i.y2018.rel
						findWil.y2019.rel += i.y2019.rel
					else
						aggWil.push i
				# upsert each item to parent
				for i in aggWil
					selector =
						kab: '*'
						kec: '*'
						kel: '*'
						elemen: i.elemen
						indikator: i.indikator
					if isKab then selector.kab = i.kab
					if isKec then selector.kec = i.kec
					modifier =
						y2015: i.y2015
						y2016: i.y2016
						y2017: i.y2017
						y2018: i.y2018
						y2019: i.y2019
					coll.elemens.upsert selector, $set: modifier

			sumit {kel: {$ne: '*'}}, true, true
			sumit {kec: {$ne: '*'}, kel: '*'}, true
			sumit {kab: {$ne: '*'}, kec: '*', kel: '*'}

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

		Meteor.publish 'coll', (name, selector, options) ->
			coll[name].find selector, options
