if Meteor.isServer

	Meteor.publish 'coll', (name, selector, options) ->
		coll[name].find selector, options

	Meteor.methods

		import: (name, selector, modifier) ->
			coll[name].upsert selector, $set: modifier
		empty: (name, selector) ->
			coll[name].remove selector
		update: (name, obj) ->
			coll[name].update obj._id, $set: obj

		wilSum: ->
			years = _.map [2015..2019], (i) -> 'y' + i
			sumit = (wil, filter) ->
				source = coll.elemens.find(filter).fetch()
				uniqBy = _.uniqBy source, (i) ->
					arr = [i.elemen, i.indikator]
					if wil is 'kec'
						arr.push i.kab, i.kec
					else if wil is 'kab'
						arr.push i.kab
					_.join arr
				for i in uniqBy
					selector = elemen: i.elemen, indikator: i.indikator
					sumer = elemen: i.elemen, indikator: i.indikator
					if wil is 'kec'
						selector.kab = i.kab; selector.kec = i.kec; selector.kel = '*'
						sumer.kab = i.kab; sumer.kec = i.kec; sumer.kel = $ne: '*'
					else if wil is 'kab'
						selector.kab = i.kab; selector.kec = '*'; selector.kel = '*'
						sumer.kab = i.kab; sumer.kec = $ne: '*'; sumer.kel = '*'
					else if wil is 'riau'
						selector.kab = '*'; selector.kec = '*'; selector.kel = '*'
						sumer.kab = $ne: '*'; sumer.kec = '*'; sumer.kel = '*'
					modifier = {}
					for j in years
						i[j].rel = _.sumBy coll.elemens.find(sumer).fetch(), (k) -> k[j].rel
						modifier[j] = i[j]
					coll.elemens.upsert selector, $set: modifier

			sumit 'kec',  {kab:{$ne:'*'}, kec:{$ne:'*'}, kel:{$ne:'*'}}
			sumit 'kab',  {kab:{$ne:'*'}, kec:{$ne:'*'}, kel:'*'      }
			sumit 'riau', {kab:{$ne:'*'}, kec:'*'      , kel:'*'      }

		wilStat: ->
			state = (selector, years, kab, kec, kel) ->
				stats = []
				maped = _.map coll.elemens.find(selector).fetch(), (i) ->
					i.indikator = 0
					for j in years
						i[j].kin = i[j].rel / i[j].tar
						i[j].sumKin = 0
					i
				console.log maped
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
					console.log selector, modifier
					# coll.wilStat.upsert selector, $set: modifier

			years = _.map [2015..2019], (i) -> 'y' + i
			state {kel: {$ne: '*'}}, years, true, true, true
			state {kec: {$ne: '*'}, kel: '*'}, years, true, true
			state {kab: {$ne: '*'}, kec: '*', kel: '*'}, years, true
			state {kab: '*', kec: '*', kel: '*'}, years
