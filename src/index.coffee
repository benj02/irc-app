### global ko ###
### global io ###
### global moment ###

$ ->
  $("input[type=tel]").on "click", ->
    @select()

NUMERIC_REGEX   = /^((\.[0-9]+)|([0-9]+\.[0-9]+)|([0-9]+\.)|([0-9]+))$/m
WORKORDER_REGEX = /^([0-9]+)\-?([0-9]+)\.?$/m

# 0.42lbs box
BOX_MAX = 34.5

class AppViewModel
  constructor: ->
    @socket = io.connect()

    # File Fields
    # Numeric
    @materialDesignation = ko.observable("")
    @stockThickness      = ko.observable("")
    @finishThickness     = ko.observable("")
    @stockWidth          = ko.observable("")
    @facemillTool        = ko.observable("")
    @workOrder           = ko.observable("")

    # Boolean
    @faub  = ko.observable(false)
    @clad  = ko.observable(false)
    @face1 = ko.observable(false)
    @face2 = ko.observable(false)
    @face3 = ko.observable(false)
    @face4 = ko.observable(false)

    # For all user fields make sure changes enable the write button
    @materialDesignation.subscribe @onChange.bind(this)
    @stockThickness.subscribe      @onChange.bind(this)
    @finishThickness.subscribe     @onChange.bind(this)
    @stockWidth.subscribe          @onChange.bind(this)
    @facemillTool.subscribe        @onChange.bind(this)
    @workOrder.subscribe           @onChange.bind(this)
    @faub.subscribe                @onChange.bind(this)
    @clad.subscribe                @onChange.bind(this)
    @face1.subscribe               @onChange.bind(this)
    @face2.subscribe               @onChange.bind(this)
    @face3.subscribe               @onChange.bind(this)
    @face4.subscribe               @onChange.bind(this)

    # Print Labels form
    @partWeight      = ko.observable()
    @partQty         = ko.observable()
    @workOrderLabel  = ko.computed =>
      str = @workOrder()
      str = str?.slice(0, 2) + "-" + str?.slice(2)
      str = str?.replace ".", ""
    @showPleaseWait  = ko.observable(false)

    @boxResult = ko.computed @computeBoxResult.bind(this)

    # Other Fields
    @faces = ko.computed => i for i in [1..4] when this["face#{i}"]()

    @file        = ko.observable("")
    @filePreview = ko.observable("")

    @requestingHelp = ko.observable(false)

    @password    = ko.observable("")
    @showConfirm = ko.observable(false)
    @showBoxes   = ko.observable(false)
    @flash       = ko.observable("")
    @infoFlash   = ko.observable("")
    @outdated    = ko.observable(false)
    @updatedAt   = ko.observable(moment())
    @updatedAgo  = ko.observable()

    @enableWrite = ko.computed =>
      @password() is "565"

    @updatedAt.subscribe @updateTimer.bind(this)
    setInterval @updateTimer.bind(this), 10 * 1000

    @socket.on "connect", =>
      $("#connect").html "<span
        class='glyphicon glyphicon-ok'
        aria-hidden='true'
        style='color: green'></span>"

      setTimeout @loadFromHash.bind(this), 500

    @socket.on "disconnect", =>
      @flash "Connection lost, refreshing"
      window.location.reload()

    @socket.on "update", @updateObservables.bind(@)
    @socket.on "preview", @showPreview.bind(@)
    @socket.on "setHelp", @requestingHelp.bind(@)

  toggleHelp: ->
    @requestingHelp !@requestingHelp()
    @socket.emit "setHelp", @requestingHelp()

  onChange: ->
    @outdated true

  updateTimer: ->
    @updatedAgo @updatedAt().fromNow()

  updateObservables: (data) ->
    gcodeToBool = (val) ->
      switch val
        when "0." then false
        when "1." then true
        else false

    @materialDesignation data.materialDesignation
    @stockThickness      data.stockThickness
    @finishThickness     data.finishThickness
    @stockWidth          data.stockWidth
    @facemillTool        data.facemillTool
    @workOrder           data.workOrder

    @faub gcodeToBool(data.faub)
    @clad gcodeToBool(data.clad)

    @file data.file if data.file # Wont be here if data comes from URL hash

    this["face#{+i}"](false) for i in [1 .. 4]
    j = data.loopStart
    i = 0
    while i < data.loopIter
      this["face#{+j}"](true)
      j++
      i++

    @showConfirm false
    @outdated false
    @flash ""
    @infoFlash ""
    @updatedAt moment()

  serializeObservables: ->
    {
      materialDesignation: @materialDesignation()
      stockThickness:      @stockThickness()
      finishThickness:     @finishThickness()
      stockWidth:          @stockWidth()
      facemillTool:        @facemillTool()
      workOrder:           @workOrder()

      faub: if @faub() then "1." else "0."
      clad: if @clad() then "1." else "0."

      loopStart: @faces()[0].toString() + "."
      loopIter: @faces().length.toString() + "."
    }

  loadFromHash: ->
    hash = window.location.hash.slice 1
    if hash
      data = JSON.parse(decodeURIComponent(hash))
      @materialDesignation data.materialDesignation
      @stockThickness      data.stockThickness
      @finishThickness     data.finishThickness
      @stockWidth          data.stockWidth
      @workOrder           data.workOrder
      @faub                data.faub
      @clad                data.clad

      @infoFlash "Some of these values have been automatically pre-filled"

  verifyAndReformatObservables: ->
    i = @workOrder().indexOf("-")
    @workOrder @workOrder().slice(0, i) + @workOrder().slice(i + 1) if i isnt -1

    addDecimalPoint = (val) ->
      val(val() + ".") if val().indexOf(".") is -1 and val().length > 0

    addDecimalPoint @materialDesignation
    addDecimalPoint @stockThickness
    addDecimalPoint @finishThickness
    addDecimalPoint @workOrder

    # coffeelint: disable=max_line_length
    return "Material Designation is not correct" if !NUMERIC_REGEX.test @materialDesignation()
    return "Stock Thickness is not correct" if !NUMERIC_REGEX.test @stockThickness()
    return "Finish Thickness is not correct" if !NUMERIC_REGEX.test @finishThickness()
    return "Stock Width is not correct" if !NUMERIC_REGEX.test @stockWidth()
    return "Facemill Tool is not correct" if !NUMERIC_REGEX.test @facemillTool()
    return "Work Order is not correct" if !NUMERIC_REGEX.test @workOrder()
    # coffeelint: enable=max_line_length

    faces = @faces()
    return "You must pick at least one face" if faces.length is 0

    return "Faces are not sequential" unless faces.every (item, index, arr) ->
      if index isnt arr.length - 1
        arr[index + 1] is item + 1
      else
        true

    false

  computeBoxResult: ->
    fullBoxCount = 0
    fullBoxQty = 0
    fullBoxWeight = 0
    leftover = 0
    leftoverWeight = 0

    # Yeah this is a pretty dumb way of calculating this
    fullBoxes = []
    currentBoxQty = 0
    for _ in [1 .. @partQty()]
      if (currentBoxQty + 1) * @partWeight() <= BOX_MAX
        currentBoxQty++
      else
        fullBoxes.push currentBoxQty
        currentBoxQty = 1
    leftover = currentBoxQty
    fullBoxCount = fullBoxes.length
    fullBoxQty = fullBoxes[0]

    fullBoxWeight = fullBoxQty * @partWeight()
    leftoverWeight = leftover * @partWeight()

    return {
      partWeight: @partWeight()
      fullBoxCount: fullBoxCount
      fullBoxQty: fullBoxQty
      leftover: leftover
      fullBoxWeight: Math.round10(fullBoxWeight, -2)
      leftoverWeight: Math.round10(leftoverWeight, -2)
      workorder: @workOrderLabel()
    }

  printLabels: ->
    $.post "/labels", @boxResult(), =>
      @showPleaseWait true
      setTimeout =>
        @showBoxes false
        @showPleaseWait false
      , 3900 # About how long it takes to start printing usually

  writeConfirm: ->
    @flash ""
    err = @verifyAndReformatObservables()
    if !err
      @socket.emit "confirm", @serializeObservables()
    else
      @flash err

  write: ->
    @flash ""
    @infoFlash ""
    err = @verifyAndReformatObservables()
    if !err
      @socket.emit "write", @serializeObservables()
    else
      @flash err

  showPreview: (text) ->
    @password ""
    @showConfirm true
    @filePreview text

  hidePreview: ->
    @password ""
    @showConfirm false
    @filePreview ""

ko.bindingHandlers.modalVisible =
  init: (el, val) ->
    $(el).modal
      show: false
      backdrop: "static"
      keyboard: false

  update: (el, val) ->
    if val()()
      $(el).modal "show"
    else
      $(el).modal "hide"

viewmodel = new AppViewModel()
ko.applyBindings viewmodel
