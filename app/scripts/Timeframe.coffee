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

class Timeframe extends Backbone.View
  constructor: (target, options = {}) ->
    @options =
      apiKey: 'beb8b17f735b6a404dbe120fd7300460'
      numImages: [12, 60, 60]
      topMargin: 230
      timesOfDay: [
        [0, 4, 'night']
        [4, 12, 'morning']
        [12, 17, 'afternoon']
        [17, 20, 'evening']
        [20, 24, 'night']
      ]

    _.defaults(options, @options)

    @loadUtility = skone.util.ImageLoader.LoadImageSet

    @totalImages = @options.numImages.reduce (a, b) ->
      a + b

    @elTarget = $(target)

    @elLoader = @elTarget.find('#loader')
    @elCityLoading = @elLoader.find('.city-loading')

    @elImgContainer = @elTarget
    @elImgList = @elImgContainer.find('ul')
    @elImgListItems = @elImgList.find('li')

    @initSearchBox()
    @setup()

  initSearchBox: () ->
    @citySearch = new CitySearchView

    @dispatcher.bind 'city_name_change', () =>
      @initialize()

  setup: () ->
    $('body').removeClass('no-js')
      .addClass('initialized')

    @elImgListItems.each (index, value) ->
      $(this).append '<h3 /><ul />'

    @elHours = @elImgListItems.eq 0
    @elMinutes = @elImgListItems.eq 1
    @elSeconds = @elImgListItems.eq 2

    @elHoursList = @elHours.find 'ul'
    @elHoursLabel = @elHours.find 'h3'
    @elMinutesList = @elMinutes.find 'ul'
    @elMinutesLabel = @elMinutes.find 'h3'
    @elSecondsList = @elSeconds.find 'ul'
    @elSecondsLabel = @elSeconds.find 'h3'

  initialize: () ->
    @cityName = @citySearch.getCityName()

    @elCityLoading.text @cityName

    @date = new Date
    @timezone = @date.toString().replace(/^.*\(|\)$/g, "").replace(/[^A-Z]/g, "")

    @citySearch.elCityPicker.fadeOut().remove()
    @elLoader.fadeIn()

    @setTime()
    @setTags()
    @queryAPI()

  setTime: () ->
    @date.setSeconds(@date.getSeconds() + 1)

    # TODO: visual representation of time zone: EST, PST, etc.
    @timezoneOffset = @date.getTimezoneOffset() / 60

  setTags: () ->
    currentTagArr = undefined
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
    "tag_mode=all&per_page=132&format=json&jsoncallback=?"

  getPhotoURL: (photo) ->
    "http://farm#{photo.farm}.static.flickr.com/" +
    "#{photo.server}/" +
    "#{photo.id}_#{photo.secret}_z.jpg"

  queryAPI: () ->
    console.log('showing '+@cityName+' in the '+ @currentTag)

    $.getJSON @getJSONURL(), (response) =>
      @response = response

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

    @loadUtility photoUrls, () =>
      list = @hoursList


  printTime: () ->

  moveStack: () ->

  module.exports = Timeframe
