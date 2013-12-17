###
 * Timeframe ViewController
 * @author: Marcy Sutton
 * Version 2.0
 * 12/5/13
###

# global $

Backbone = require 'backbone'
Backbone.$ = $

CitySearchView = require './views/CitySearch'
StackView = require './views/Stack'
Clock = require './models/Clock'

class Timeframe extends Backbone.View
  constructor: (target, options = {}) ->
    @options =
      apiKey: 'beb8b17f735b6a404dbe120fd7300460'
      numImages: [12, 60, 60]
      timesOfDay: [
        [0, 4, 'night']
        [4, 12, 'morning']
        [12, 17, 'afternoon']
        [17, 20, 'evening']
        [20, 24, 'night']
      ]

    _.defaults(options, @options)

    @loadUtility = skone.util.ImageLoader.LoadImageSet

    @elTarget = $(target)
    @elLoader = $('.loader')
    @elCityLoading = @elLoader.find('.city-loading')
    @elNowShowing = @elTarget.find('.now-showing')

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

  initializeApp: () ->
    @cityName = @citySearch.getCityName()
    @updateUIWithCityChange @cityName

    @citySearch.elCityPicker.fadeOut().remove()
    @elLoader.fadeIn()

    @date = new Date

    @clock = new Clock(@stacks, @cityName)
    @clock.setTime()
    @queryAPI()

  updateUIWithCityChange: (cityName) ->
    @elCityLoading.text cityName

  setTags: (firstAttempt) ->
    currentTagArr = []
    currentHour = @date.getHours()
    tags = @options.timesOfDay
    numTags = tags.length

    i = 0
    while i < numTags
      currentTagArr = tags[i]
      if currentHour >= currentTagArr[0] and currentHour < currentTagArr[1]
        @currentTag = currentTagArr[2]
        break
      i++

  queryAPI: () ->
    @setTags()

    $.getJSON(@getJSONURL(), (response) =>
      console.log('showing '+@cityName+' in the '+ @currentTag)

      @elNowShowing.text "#{@cityName} #{@currentTag}"

      console.log response

      if response.stat == "ok"
        console.log 'number of images: ', response.photos.photo.length
        @fetchImages response
      else
        @showErrorMessage response.message

    ).fail (response) =>
      @showErrorMessage response

  showErrorMessage: (response) ->
    if response.message
      alert response.message
    else
      alert 'Sorry, there was a problem. Please try again!'

    console.log response

  getJSONURL: () ->
    "http://api.flickr.com/services/rest/?method=flickr.photos.search&" +
    "api_key=#{@options.apiKey}&" +
    @getURLTags() +
    "per_page=" + @getTotalImages() +
    "&format=json&jsoncallback=?"

  getURLTags: () ->
    tagParams = "tag_mode=all&tags="

    tags = "#{@cityName.replace(' ','+')}"
    tags += ",#{@currentTag}&"

    tagParams + tags

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
    @elNowShowing.fadeIn()
    @clock.startInterval()

    @clock.on "change:time", (event) =>
      @moveStacks()

  initPhotoStacks: () ->
    for stack in @stacks
      stack.elListItems = stack.elList.find('li')

      stack.setCurrentFrame(@clock.date)
      stack.positionClockNumbers()

  moveStacks: () ->
    @secondsStack.moveStack @clock.currentSeconds, @clock.formattedSeconds
    @minutesStack.moveStack @clock.currentMinutes, @clock.formattedMinutes
    @hoursStack.moveStack @clock.currentHours, @clock.formattedHours

  module.exports = Timeframe
