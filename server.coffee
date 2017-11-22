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
		tems: ->
			source = coll.tem.find().fetch()
			grups = _.uniqBy source, (i) -> i.grup
			items = _.map grups, (i) ->
				filter = _.filter source, (j) -> j.grup is i.grup
				grup: i.grup, items: _.uniq _.map filter, (j) -> j.item
			_.filter items, (i) -> i.grup
