ko.components.register "check-button",
  viewModel: (params) ->
    @val  = params.value
    @text = params.text

    @toggle = => @val !@val()
    return this

  template:
    """
    <button
      class="btn"
      data-bind="
        click: toggle,
        css: { 'btn-success': val, 'btn-danger': !val() }">
      <span data-bind="text: text"></span>
      <span
        class='glyphicon'
        data-bind="css: { 'glyphicon-ok': val, 'glyphicon-remove': !val() }">
      </span>
    </button>
    """
