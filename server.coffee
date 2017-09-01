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

			years = _.map [2015..2019], (i) -> 'y' + i
			sumit = (wil, selector) ->
				num = 0
				source = coll.elemens.find(selector).fetch()
				uniqBy = _.uniqBy source, (i) ->
					arr = [i.elemen, i.indikator]
					if wil is 'kec'
						arr.push i.kab, i.kec
					else if wil is 'kab'
						arr.push i.kab
					_.join arr
				for i in uniqBy
					sel = elemen: i.elemen, indikator: i.indikator, kel: '*'
					if wil is 'kec'
						sel.kab = i.kab; sel.kec = i.kec
					else if wil is 'kab'
						sel.kab = i.kab; sel.kec = '*'
					else
						sel.kab = '*'; sel.kec = '*'
					modifier = {}
					for j in years
						i[j].rel = _.sumBy coll.elemens.find(sel).fetch(), (k) -> k[j].rel
						modifier[j] = i[j]
					coll.elemens.upsert sel, $set: modifier
					console.log sel, modifier, ++num

			sumit 'kec', {kel: {$ne: '*'}}
			sumit 'kab', {kab: {$ne: '*'}, kel: '*'}
			sumit 'riau', {kab: '*', kec: '*', kel: '*'}

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
