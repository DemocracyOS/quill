Quill   = require('../quill')
Tooltip = require('./tooltip')
_       = Quill.require('lodash')
dom     = Quill.require('dom')
Delta   = Quill.require('delta')
Range   = Quill.require('range')


class VideoTooltip extends Tooltip
  @DEFAULTS:
    template:
     '<input class="input" type="textbox">
      <div class="preview">
        <span>Preview</span>
      </div>
      <a href="javascript:;" class="cancel">Cancel</a>
      <a href="javascript:;" class="insert">Insert</a>'

  constructor: (@quill, @options) ->
    @options = _.defaults(@options, Tooltip.DEFAULTS)
    super(@quill, @options)
    @embedURL = ''
    @preview = @container.querySelector('.preview')
    @textbox = @container.querySelector('.input')
    dom(@container).addClass('ql-video-tooltip')
    config =
      tag: 'IFRAME'
      attribute: 'src'

    @quill.addFormat('video', config)
    this.initListeners()

  initListeners: ->
    dom(@container.querySelector('.insert')).on('click', _.bind(this.insertVideo, this))
    dom(@container.querySelector('.cancel')).on('click', _.bind(this.hide, this))
    dom(@textbox).on('input', _.bind(this._preview, this))
    this.initTextbox(@textbox, this.insertVideo, this.hide)
    @quill.onModuleLoad('toolbar', (toolbar) =>
      toolbar.initFormat('video', _.bind(this._onToolbar, this))
    )

  insertVideo: ->
    this._normalizeURL(@textbox.value)
    @range = new Range(0, 0) unless @range?   # If we lost the selection somehow, just put image at beginning of document
    if @range
      @preview.innerHTML = '<span>Preview</span>'
      @textbox.value = ''
      index = @range.end
      @quill.insertEmbed(index, 'video', @embedURL, 'user')
      @quill.setSelection(index + 1, index + 1)
    this.hide()

  _onToolbar: (range, value) ->
    if value
      @textbox.value = 'http://' unless @textbox.value
      this.show()
      @textbox.focus()
      _.defer( =>
        @textbox.setSelectionRange(@textbox.value.length, @textbox.value.length)
      )
    else
      @quill.deleteText(range, 'user')

  _preview: ->
    this._normalizeURL(@textbox.value)
    # return unless this._matchVideoURL(@textbox.value)
    if @preview.firstChild.tagName == 'IFRAME'
      @preview.firstChild.setAttribute('src', @embedURL)
    else
      img = document.createElement('iframe')
      img.setAttribute('src', @embedURL)
      @preview.replaceChild(img, @preview.firstChild)

  _matchVideoURL: (url) ->
    return true
    # return /^https?:\/\/.+\.(jpe?g|gif|png)$/.test(url)

  _normalizeURL: (url) ->
    url = new URL(url)
    if /youtube.com$/.test(url.hostname)
      @provider = 'youtube'
      this._normalizeYoutubeURL(url)
    else if /vimeo.com$/.test(url.hostname)
      @provider = 'vimeo'
      this._normalizeVimeoURL(url)
    else if /dailymotion.com$/.test(url.hostname)
      @provider = 'dailymotion'
      this._normalizeDailymotionURL(url)

  _normalizeVimeoURL: (url) ->
    if url.protocol == "https:"
      vimeoID = url.toString().substring(18)
    else
      vimeoID = url.toString().substring(17)
    @embedURL = "#{url.protocol}//player.vimeo.com/video/#{vimeoID}"

  _normalizeYoutubeURL: (url) ->
    if url.toString().length > 28
      queryString = {}
      url.toString().replace(new RegExp("([^?=&]+)(=([^&]*))?", "g"), ($0, $1, $2, $3) -> queryString[$1] = $3)
      youtubeID = queryString['v']
    else
      youtubeID = youtubeURL.substring(16)
    @embedURL = "http://www.youtube.com/embed/#{youtubeID}"

  _normalizeDailymotionURL: (url) ->
    dailymotionID = if (m = url.toString().match(new RegExp("\/video\/([^_?#]+).*?"))) then m[1] else "void 0"
    @embedURL = "http://www.dailymotion.com/embed/video/#{dailymotionID}"

Quill.registerModule('video-tooltip', VideoTooltip)
module.exports = VideoTooltip
