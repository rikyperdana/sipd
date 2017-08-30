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
			state = (selector, years, kab, kec, kel) ->
				stats = []
				maped = _.map coll.elemens.find(selector).fetch(), (i) ->
					i.indikator = 0
					for j in years
						i[j].kin = i[j].rel / i[j].tar
						i[j].sumKin = 0
					i
				for i in maped
					find = _.find stats, (j) ->
						elem = -> j.elemen is i.elemen
						kab = -> j.kab is i.kab
						kec = -> j.kec is i.kec
						kel = -> j.kel is i.kel
						if kel
							elem() and kab() and kec() and kel()
						else if kec
							elem() and kab() and kec()
						else if kab
							elem() and kab()
						else
							elem
					if find
						find.indikator += 1
						for j in years
							find[j].sumKin += i[j].kin
							find[j].avgKin = find[j].sumKin / find.indikator
					else
						stats.push i
				for i in stats
					selector = elemen: i.elemen
					if kab then selector.kab = i.kab
					if kec then selector.kec = i.kec
					if kel then selector.kel = i.kel
					modifier = indikator: i.indikator
					for j in years
						modifier[j] = sumKin: i[j].sumKin, avgKin: i[j].avgKin
					coll.wilStat.upsert selector, $set: modifier

			years = _.map [2015..2019], (i) -> 'y' + i
			state {kel: {$ne: '*'}}, years, true, true, true
			state {kec: {$ne: '*'}, kel: '*'}, years, true, true
			state {kab: {$ne: '*'}, kec: '*', kel: '*'}, years, true
			state {kab: '*', kec: '*', kel: '*'}, years
























			###
			statKecs = []
			maped = _.map coll.elemens.find({kel:{$ne: '*'}}).fetch(), (i) ->
				i.indikator = 0
				i.y2015.kin = i.y2015.rel / i.y2015.tar
				i.y2015.sumKin = 0
				i.y2016.kin = i.y2016.rel / i.y2016.tar
				i.y2016.sumKin = 0
				i.y2017.kin = i.y2017.rel / i.y2017.tar
				i.y2017.sumKin = 0
				i.y2018.kin = i.y2018.rel / i.y2018.tar
				i.y2018.sumKin = 0
				i.y2019.kin = i.y2019.rel / i.y2019.tar
				i.y2019.sumKin = 0
				i
			for i in maped
				findKec = _.find statKecs, (j) ->
					kab = j.kab is i.kab
					kec = j.kec is i.kec
					kel = j.kel is i.kel
					elem = j.elemen is i.elemen
					kab and kec and kel and elem
				if findKec
					findKec.indikator += 1
					findKec.y2015.sumKin += i.y2015.kin
					findKec.y2015.avgKin = findKec.y2015.sumKin / findKec.indikator
					findKec.y2016.sumKin += i.y2016.kin
					findKec.y2016.avgKin = findKec.y2016.sumKin / findKec.indikator
					findKec.y2017.sumKin += i.y2017.kin
					findKec.y2017.avgKin = findKec.y2017.sumKin / findKec.indikator
					findKec.y2018.sumKin += i.y2018.kin
					findKec.y2018.avgKin = findKec.y2018.sumKin / findKec.indikator
					findKec.y2019.sumKin += i.y2019.kin
					findKec.y2019.avgKin = findKec.y2019.sumKin / findKec.indikator
				else
					statKecs.push i
			for i in statKecs
				selector =
					kab: i.kab
					kec: i.kec
					kel: i.kel
					elemen: i.elemen
				modifier =
					indikator: i.indikator
					y2015: sumKin: i.y2015.sumKin, avgKin: i.y2015.avgKin
					y2016: sumKin: i.y2016.sumKin, avgKin: i.y2016.avgKin
					y2017: sumKin: i.y2017.sumKin, avgKin: i.y2017.avgKin
					y2018: sumKin: i.y2018.sumKin, avgKin: i.y2018.avgKin
					y2019: sumKin: i.y2019.sumKin, avgKin: i.y2019.avgKin
				# console.log selector, modifier
				coll.wilStat.upsert selector, $set: modifier
			###

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
