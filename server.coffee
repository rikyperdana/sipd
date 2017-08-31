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
				num = 0
				source = coll.elemens.find(selector).fetch()
				uniqBy = _.uniqBy source, (i) ->
					arr = [i.elemen, i.indikator]
					if isKab then arr.push i.kab
					if isKec then arr.push i.kec
					_.join arr
				forEach = _.forEach uniqBy, (i) ->
					sel = {}
					sel.elemen = i.elemen
					sel.indikator = i.indikator
					sel.kel = '*'

					sel.kab = i.kab
					sel.kec = i.kec
					

					i.y2015.rel = _.sumBy coll.elemens.find(sel).fetch(), (j) -> j.y2015.rel
					modifier =
						y2015: i.y2015
					coll.elemens.upsert sel, $set: modifier
					console.log modifier, ++num

			sumit {kel: {$ne: '*'}}, true, true
			sumit {kec: {$ne: '*'}, kel: '*'}, true
			sumit {kab: {$ne: '*'}, kec: '*', kel: '*'}








			###
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
			###

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
