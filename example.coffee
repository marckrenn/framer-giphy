

amazeballz = new Layer
	frame: Screen.frame
	image: giphy.search("giphy", 2)

amazeballz.onTouchStart -> @image = giphy.random("awesome")

stickerCount = 15
stickerSize = Screen.width / stickerCount

giphy.trending {limit: stickerCount, stickers: true}, (stickers) ->

	for sticker, i in stickers
		trendingSticker = new Layer
			size: stickerSize
			maxY: Screen.height
			x: stickerSize * i
			image: sticker


