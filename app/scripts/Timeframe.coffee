###
 * Timeframe
 * @author: Marcy Sutton
 * Version 2.0
 * 12/5/13
###

# global $

Backbone = require 'backbone'
Backbone.$ = $

CitySearchView = require './views/CitySearch'
StackView = require './views/Stack'
Clock = require './Clock'

class Timeframe extends Backbone.View
  constructor: (target, options = {}) ->
    @options =
      apiKey: 'beb8b17f735b6a404dbe120fd7300460'
      numImages: [12, 60, 60]
      timesOfDay: [
        [0, 4, 'night', 'night']
        [4, 12, 'morning', 'day']
        [12, 17, 'afternoon', 'day']
        [17, 20, 'evening', 'night']
        [20, 24, 'night', 'night']
      ]

    _.defaults(options, @options)

    @loadUtility = skone.util.ImageLoader.LoadImageSet

    @elTarget = $(target)
    @elLoader = $('.loader')
    @elCityLoading = @elLoader.find('.city-loading')

    @initSearchBox()
    @setupClockUI()

  getTotalImages: () ->
    @options.numImages.reduce (a, b) ->
      a + b

  initSearchBox: () ->
    @citySearch = new CitySearchView

    @dispatcher.bind 'city_name_change', () =>
      @initializeApp()

  setupClockUI: () ->
    $('body').removeClass('no-js')
      .addClass('initialized')

    @elImgContainer = @elTarget
    @elImgList = @elImgContainer.find('ul.imgStacks')
    @elImgListItems = @elImgList.find('li')

    @elImgListItems.each (index, value) ->
      $(this).append '<h3 /><ul />'

    @elHours = @elImgListItems.eq 0
    @elMinutes = @elImgListItems.eq 1
    @elSeconds = @elImgListItems.eq 2

    @hoursStack = new StackView @elHours
    @minutesStack = new StackView @elMinutes
    @secondsStack = new StackView @elSeconds
    @stacks = [@hoursStack, @minutesStack, @secondsStack]

    @imageStackObj = {}

    @clock = new Clock(@stacks)

  initializeApp: () ->
    @cityName = @citySearch.getCityName()
    @updateUIWithCityChange @cityName

    @citySearch.elCityPicker.fadeOut().remove()
    @elLoader.fadeIn()

    @date = new Date

    @clock.setTime()
    @queryAPI(true)

  updateUIWithCityChange: (cityName) ->
    @elCityLoading.text cityName

  queryAPI: (timeOfDay) ->
    @setTags(timeOfDay)

    $.getJSON(@getJSONURL(timeOfDay), (response) =>
      console.log('showing '+@cityName+' in the '+ @currentTag)

      console.log response
      if response.stat == "ok"
        console.log 'number of images: ', response.photos.photo.length
        @fetchImages response

        # if response.photos.photo.length >= 132
        #   @fetchImages response
        # else
        #   @queryAPI(false)
        #
    ).fail (response) =>
      @showErrorMessage response.message

  showErrorMessage: (message) ->
    alert message

  setTags: (firstAttempt) ->
    currentTagArr = []
    currentHour = @date.getHours()
    tags = @options.timesOfDay
    numTags = tags.length

    i = 0
    while i < numTags
      currentTagArr = tags[i]
      if currentHour >= currentTagArr[0] and currentHour < currentTagArr[1]
        @currentTag = (if firstAttempt then currentTagArr[2] else currentTagArr[3])
        break
      i++

  getJSONURL: (timeOfDay) ->
    "http://api.flickr.com/services/rest/?method=flickr.photos.search&" +
    "api_key=#{@options.apiKey}&" +
    "tags=" + @getURLTags(timeOfDay)+ "&tag_mode=all&" +
    "per_page=" + @getTotalImages() +
    "&format=json&jsoncallback=?"

  getURLTags: (timeOfDay) ->
    tagParams = "#{@cityName.replace(' ','+')}"
    tagParams += ",#{@currentTag}" if timeOfDay
    tagParams

  getPhotoURL: (photo) ->
    "http://farm#{photo.farm}.static.flickr.com/" +
    "#{photo.server}/" +
    "#{photo.id}_#{photo.secret}_z.jpg"

  fetchImages: (response) ->
    photoUrls = []

    $.each response.photos.photo, (n, item) =>
      photo = response.photos.photo[n]

      t_url = @getPhotoURL(photo)

      photoUrls.push t_url

    @loadImages(photoUrls)

  addImageToStackObject: (stack, imageUrl) ->
    @imageStackObj[stack.id] = {} unless @imageStackObj.hasOwnProperty stack.id

    @imageStackObj[stack.id].time = stack.relevantTime

    @imageStackObj[stack.id].urls = [] unless @imageStackObj[stack.id].hasOwnProperty 'urls'
    @imageStackObj[stack.id].urls.push imageUrl

  loadImages: (photoUrls) ->
    @loadUtility photoUrls, () =>

      i = 0
      while i < photoUrls.length
        if i > 11 and i < 72

          stack = @minutesStack
          stack.relevantTime = @date.getMinutes()

          @addImageToStackObject stack, photoUrls[i]

        else if i >= 72
          stack = @secondsStack
          stack.relevantTime = @date.getSeconds()

          @addImageToStackObject stack, photoUrls[i]

        else
          stack = @hoursStack
          stack.relevantTime = @date.getHours12()

          @addImageToStackObject stack, photoUrls[i]

        stack.elList.append $('<li>')
          .addClass('flickr')
          .append $("<div><img src='#{photoUrls[i]}' /></div>")

        i++

      @initPhotoStacks()
      @startClock()

  startClock: () ->
    @elLoader.remove()
    @clock.startInterval()

  initPhotoStacks: () ->
    for stack in @stacks
      stack.elListItems = stack.elList.find('li')

      stack.moveStack()
      stack.positionClockNumbers()

  module.exports = Timeframe
