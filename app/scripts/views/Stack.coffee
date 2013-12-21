Backbone.$ = $

class StackView extends Backbone.View

  options:
    initTopMargin: 230

  relevantTime: null

  formattedTime: null

  currentFrame: null

  constructor: (target) ->
    @el = $(target)

    @id = target.attr 'id'

    @elList = @el.find 'ul'
    @elLabel = @el.find 'h3'

  setStackUlPosition: (element, relevantTime) ->
    @ulTopMargin = @options.initTopMargin - (relevantTime * 15)
    element.css "top", "#{@ulTopMargin}px"

  setTime: (relevantTime, formattedTime) ->
    @relevantTime = relevantTime
    @formattedTime = formattedTime

  updateClockUnit: () ->
    @elLabel.text(@formattedTime)

  positionClockNumbers: () ->
    currentFramePosition = @ulTopMargin + @currentFrame.position().top
    @elLabel.css 'top', currentFramePosition

    @elLabel.fadeIn()

  setCurrentFrame: () ->
    @setStackUlPosition @elList, @relevantTime

    @currentFrame.removeClass 'current' if @currentFrame
    @currentFrame = $(@elListItems[@relevantTime])

    @currentFrame.addClass 'current'

  moveStack: () ->
    @setCurrentFrame()
    @updateClockUnit()

module.exports = StackView
