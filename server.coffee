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
