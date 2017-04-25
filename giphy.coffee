

# based on http://stackoverflow.com/a/11654596 by ellemayo
urlEncode = (url, keyValues) ->

	updateQueryString = (key, value, url) ->
		re = new RegExp("([?&])#{key}=.*?(&|#|$)(.*)", "gi")
		hash = undefined

		if re.test(url)

			if typeof value isnt "undefined" and value isnt null
				url.replace(re, "$1#{key}=#{value}$2$3")

			else
				hash = url.split("#")
				url = hash[0].replace(re, "$1$3").replace(/(&|\?)$/, "")
				url += "##{hash[1]}" if typeof hash[1] isnt "undefined" and hash[1] isnt null
				return url

		else

			if typeof value isnt "undefined" and value isnt null
				separator = if url.indexOf("?") isnt -1 then "&" else "?"
				hash = url.split("#")
				url = "#{hash[0]}#{separator}#{key}=#{value}"
				url += "##{hash[1]}" if typeof hash[1] isnt "undefined" and hash[1] isnt null
				return url

			else url

	string = newUrl = ""

	for key, value of keyValues

		newUrl = url if newUrl is ""
		string = newUrl = updateQueryString(key, value, newUrl)

	return string


# The following is based on GIPHY API
# https://github.com/Giphy/GiphyAPI

# code should probably be restructured ... turned out that the GIPHY API is not as consistent as expected / hoped

exports.giphy = { # "Powered By Giphy"

	_queryGiphy: (path, parameters, callback) ->

		parameters ?= {}

		unless path is "gifById" or path is "gifsById"
			parameters.limit ?= 1
	
		parameters.api_key = "dc6zaTOxFJmzC"

		if parameters.fmt? then delete parameters.fmt
		if parameters.offset is 0 then delete parameters.offset

		if path is "gifById"
			id = parameters.id
			delete parameters.id
		else if path is "gifsById"
			idCount = parameters.idCount
			delete parameters.idCount

		baseUrl = "https://api.giphy.com/v1"

		if path is "gifById"
			url = "#{baseUrl}/gifs/#{id}"
		if path is "gifsById"
			url = "#{baseUrl}/gifs"
		else if parameters.stickers or parameters.sticker
			url = "#{baseUrl}/stickers/#{path}"
			if parameters.stickers? then delete parameters.stickers
			if parameters.sticker? then delete parameters.sticker
		else url = "#{baseUrl}/gifs/#{path}"

		query = urlEncode(url, parameters)


		unless callback?

			if parameters.limit > 1 or path is "gifsById"

				try
					data = Utils.domLoadJSONSync(query).data
					gifs = []
					for gif in data
						gifs.push(gif.images.original.url)
					return gifs
				catch
					console.warn("No results for query:", parameters)

			else

				if path is "random"
					try
						return Utils.domLoadJSONSync(query).data.image_original_url
					catch
						console.warn("No results for query:", parameters)

				else if path is "translate"
					try
						return Utils.domLoadJSONSync(query).data.images.original.url
					catch
						console.warn("No results for query:", parameters)

				else if path is "gifById"
					try
						return Utils.domLoadJSONSync(query).data.images.original.url
					catch
						console.warn("Invalid ID:", id)

				else
					try
						return Utils.domLoadJSONSync(query).data[0].images.original.url
					catch
						console.warn("No results for query:", parameters)

		else

			if path is "gifsById"

				Utils.domLoadJSON query, (err, data) ->
					if data.data.length isnt idCount
						console.warn("One or more invalid IDs:", parameters.ids.split(","))
					else
						gifs = []
						for gif in data.data
							gifs.push(gif.images.original.url)
						callback(gifs, data)

			else if path is "random"
	
				Utils.domLoadJSON query, (err, data) ->
					if data.data.length is 0
						console.warn("No results for query:", parameters)
					else
						callback(data.data.image_original_url, data)

			else

				Utils.domLoadJSON query, (err, data) ->

					if data.data.length is 0
						console.warn("No results for query:", parameters)
					else
						gifs = []
						for gif in data.data
							gifs.push(gif.images.original.url)
						callback(gifs, data)


	search: (query = "", offset, parameters, callback) ->

		if typeof offset is "object"
			callback = parameters
			parameters = offset
			offset = 0

		query = query.replace(/ /g, "+")

		parameters ?= {}
		parameters.q = query
		parameters.offset = offset

		@_queryGiphy("search", parameters, callback)

	trending: (offset, parameters, callback) ->

		if typeof offset is "object"
			callback = parameters
			parameters = offset

		parameters ?= {}
		parameters.offset = offset

		@_queryGiphy("trending", parameters, callback)


	translate: (query, parameters, callback) ->

		if typeof query is "object"
			callback = parameters

		query = query.replace(/ /g, "+")

		parameters ?= {}
		parameters.s = query
		parameters.limit = 1

		@_queryGiphy("translate", parameters, callback)

	random: (tag, parameters, callback) ->

		if typeof tag is "string"
			if parameters?.sticker
				tag = tag.replace(/ /g, "-")
			else
				tag = tag.replace(/ /g, "+")
			parameters ?= {}
			parameters.tag = tag
		else
			parameters = tag
		
		if typeof parameters is "function"
			callback = parameters

		parameters ?= {}
		parameters.limit = 1

		@_queryGiphy("random", parameters, callback)

	gifById: (id) ->
		parameters = {}
		parameters.id = id
		@_queryGiphy("gifById", parameters)

	gifsById: (ids, callback) ->

		unless parameters?
			parameters = {}

		parameters.idCount = ids.length
		ids = ids.join(", ").replace(/ /g, "")
		parameters.ids = ids


		@_queryGiphy("gifsById", parameters, callback)

}

