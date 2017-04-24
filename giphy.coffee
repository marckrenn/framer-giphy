

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


# based on https://github.com/Giphy/GiphyAPI

apiKey = "dc6zaTOxFJmzC"

exports.giphy = { # "Powered By Giphy"

	_queryGiphy: (path, parameters, callback) ->

		unless parameters?
			parameters = {}

		parameters.limit ?= 1
		parameters.api_key = apiKey
		if parameters.fmt? then delete parameters.fmt

		baseUrl = "https://api.giphy.com/v1"

		if path is ""
			url = "#{baseUrl}/gifs"
		else if parameters.stickers or parameters.sticker
			url = "#{baseUrl}/stickers/#{path}"
			if parameters.stickers? then delete parameters.stickers
			if parameters.sticker? then delete parameters.sticker
		else
			url = "#{baseUrl}/gifs/#{path}"

		q = urlEncode(url, parameters)

		if parameters.limit is 1

			if Array.isArray(Utils.domLoadJSONSync(q).data)
				if Utils.domLoadJSONSync(q).pagination.total_count is 0
					console.warn("No results for query: #{JSON.stringify(parameters)}.")
				else
					return Utils.domLoadJSONSync(q).data[0].images.original.url

			else
				if path is "random"
					return Utils.domLoadJSONSync(q).data.image_original_url
				else
					return Utils.domLoadJSONSync(q).data.images.original.url
		else

			Utils.domLoadJSON q, (err, data) ->
				if callback?
					gifs = []
					for gif in data.data
						gifs.push(gif.images.original.url)
					callback?(gifs, data)


	search: (query = "", offset, parameters, callback) ->

		if typeof offset is "object"
			callback = parameters
			parameters = offset

		query = query.replace(/ /g, '+')

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

		query = query.replace(/ /g, '+')

		parameters ?= {}
		parameters.s = query
		parameters.limit = 1

		@_queryGiphy("translate", parameters, callback)

	random: (tag, parameters, callback) ->

		if typeof tag is "string"
			if parameters?.sticker
				tag = tag.replace(/ /g, '-')
			else
				tag = tag.replace(/ /g, '+')
			parameters ?= {}
			parameters.tag = tag
		else
			parameters = tag

		parameters ?= {}
		parameters.limit = 1

		@_queryGiphy("random", parameters, callback)

	gifById: (id) -> @_queryGiphy(id)

	gifsById: (ids, callback) ->

		unless parameters?
			parameters = {}

		parameters.limit = ids.length

		ids = ids.join(", ").replace(/ /g,'')
		parameters.ids = ids

		@_queryGiphy("", parameters, callback)

}
