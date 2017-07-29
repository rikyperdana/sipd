if Meteor.isServer

	Meteor.publish 'elemens', (route) ->
		coll.elemens.find
			kab: route.split('_')[0]
			kec: route.split('_')[1]
			kel: route.split('_')[2]

	Meteor.methods
		import: (collName, data) ->
			coll[collName].insert data
