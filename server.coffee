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


		wilSum: (wilName, elemen) ->
			source = _.filter coll.elemens.find().fetch(), (i) ->
				if wilName.kec
					kab = i.kab is wilName.kab
					kec = i.kec is wilName.kec
					kel = i.kel isnt '*'
					true if kab and kec and kel
				else if wilName.kab is 'riau'
					kab = i.kab isnt '*'
					kec = i.kec isnt '*'
					kel = i.kel isnt '*'
					true if kab and kec and kel
				else if wilName.kab
					kab = i.kab is wilName.kab
					kec = i.kec isnt '*'
					kel = i.kel isnt '*'
					true if kab and kec and kel
			list = []
			for i in source
				find = _.find list, (j) -> j.indikator is i.indikator
				if find
					find.y2015.rel += i.y2015.rel
					find.y2016.rel += i.y2016.rel
					find.y2017.rel += i.y2017.rel
					find.y2018.rel += i.y2018.rel
					find.y2019.rel += i.y2019.rel
				else
					list.push i
			if elemen
				_.filter list, (i) -> i.elemen is elemen
			else
				list

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
