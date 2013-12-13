###
 * Timeframe
 * @author: Marcy Sutton
 * Version 2.0
 * 12/5/13
###

# global $

Backbone = require 'backbone'
Backbone.$ = $

CitySearchView = require './CitySearch'
Stack = require './Stack'

class Timeframe extends Backbone.View
  constructor: (target, options = {}) ->
    @options =
      apiKey: 'beb8b17f735b6a404dbe120fd7300460'
      numImages: [12, 60, 60]
      initTopMargin: 230
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

    @hoursStack = new Stack @elHours
    @minutesStack = new Stack @elMinutes
    @secondsStack = new Stack @elSeconds

    @stacks = [@hoursStack, @minutesStack, @secondsStack]

    @imageStackObj = {}

  initializeApp: () ->
    @cityName = @citySearch.getCityName()

    @updateUIWithCityChange @cityName

    @date = new Date
    @timezone = @date.toString().replace(/^.*\(|\)$/g, "").replace(/[^A-Z]/g, "")

    @citySearch.elCityPicker.fadeOut().remove()
    @elLoader.fadeIn()

    @setTime()
    @setTags()
    @queryAPI()

  updateUIWithCityChange: (cityName) ->
    @elCityLoading.text cityName

  setTime: () ->
    @date.setSeconds(@date.getSeconds() + 1)

    # TODO: visual representation of time zone: EST, PST, etc.
    @timezoneOffset = @date.getTimezoneOffset() / 60

  setTags: () ->
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

  getJSONURL: () ->
    "http://api.flickr.com/services/rest/?method=flickr.photos.search&" +
    "api_key=#{@options.apiKey}&" +
    "tags=#{@cityName.replace(' ','+')},#{@currentTag}&" +
    "tag_mode=all&" +
    "per_page=#{@getTotalImages()}&" +
    "format=json&jsoncallback=?"

  getPhotoURL: (photo) ->
    "http://farm#{photo.farm}.static.flickr.com/" +
    "#{photo.server}/" +
    "#{photo.id}_#{photo.secret}_z.jpg"

  queryAPI: () ->
    console.log('showing '+@cityName+' in the '+ @currentTag)

    $.getJSON @getJSONURL(), (response) =>
      @response = response

      console.log response

      if response.code == 100
        @showErrorMessage response.message

      else
        @fetchImages response

  showErrorMessage: (message) ->
    alert message

  fetchImages: (response) ->
    photoUrls = []

    $.each response.photos.photo, (n, item) =>
      photo = response.photos.photo[n]

      t_url = @getPhotoURL(photo)

      photoUrls.push t_url

    @loadImages(photoUrls)

  loadImages: (photoUrls) ->
    @loadUtility photoUrls, () =>

      i = 0
      while i < photoUrls.length
        if i > 11 and i < 72

          stack = @minutesStack
          stack.relevantTime = @date.getMinutes()

          @addToImageStackObj stack, photoUrls[i]

        else if i >= 72
          stack = @secondsStack
          stack.relevantTime = @date.getSeconds()

          @addToImageStackObj stack, photoUrls[i]

        else
          stack = @hoursStack
          stack.relevantTime = @date.getHours12()

          @addToImageStackObj stack, photoUrls[i]

        stack.elList.append $('<li>')
          .addClass('flickr')
          .append $("<div><img src='#{photoUrls[i]}' /></div>")

        i++

      @initStacks()
      @showClock()

  addToImageStackObj: (stack, imageUrl) ->
    @imageStackObj[stack.id] = {} unless @imageStackObj.hasOwnProperty stack.id

    @imageStackObj[stack.id].time = stack.relevantTime

    @imageStackObj[stack.id].urls = [] unless @imageStackObj[stack.id].hasOwnProperty 'urls'
    @imageStackObj[stack.id].urls.push imageUrl

  showClock: () ->
    @elLoader.remove()
    @printTime()
    # @startInterval @interval

  startInterval: (interval) ->
    interval = window.setInterval(=>
      @printTime()
    , 1000)

  stopInterval: (interval) ->
    window.clearInterval(interval)

  printTime: () ->
    @setTime()

    @printSeconds()
    @printMinutes()
    @printHours()

  printSeconds: () ->
    seconds = @date.getSeconds()
    formattedSeconds = (if seconds < 10 then '0' + seconds else seconds)

    @secondsStack.updateClockUnit formattedSeconds

  printMinutes: () ->
    minutes = @date.getMinutes()
    formattedMinutes = (if minutes < 10 then '0' + minutes else minutes)

    @minutesStack.updateClockUnit formattedMinutes

    # add code to loop to next minute

  printHours: () ->
    hours = @date.getHours12()
    formattedHour = (if hours < 10 then ((if hours is 0 then 12 else "0" + hours)) else hours)

    @hoursStack.updateClockUnit formattedHour

    #add code to loop to next hour

  initStacks: () ->
    for stack in @stacks
      stack.elListItems = stack.elList.find('li')

      topMargin = @options.initTopMargin - (stack.relevantTime * 15)
      stack.elList.css "top", "#{topMargin}px"

      stack.currentFrame.removeClass 'current' if stack.currentFrame
      stack.currentFrame = $(stack.elListItems[stack.relevantTime])
      stack.currentFrame.addClass 'current'

      stack.positionClockUnit $(@stacks[0].elList).height() / 2

  module.exports = Timeframe
