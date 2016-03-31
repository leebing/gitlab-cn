class @MilestoneSelect
  constructor: ->
    $('.js-milestone-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      projectId = $dropdown.data('project-id')
      milestonesUrl = $dropdown.data('milestones')
      selectedMilestone = $dropdown.data('selected')
      showNo = $dropdown.data('show-no')
      showAny = $dropdown.data('show-any')
      showUpcoming = $dropdown.data('show-upcoming')
      useId = $dropdown.data('use-id')
      defaultLabel = $dropdown.data('default-label')

      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: milestonesUrl
          ).done (data) ->
            extraOptions = []
            if showAny
              extraOptions.push(
                id: 0
                name: ''
                title: '任何里程碑'
              )

            if showNo
              extraOptions.push(
                id: -1
                name: 'No Milestone'
                title: '无里程碑'
              )

            if showUpcoming
              extraOptions.push(
                id: -2
                name: '#upcoming'
                title: '即将到来'
              )

            if extraOptions.length > 2
              extraOptions.push 'divider'

            callback(extraOptions.concat(data))
        filterable: true
        search:
          fields: ['title']
        selectable: true
        toggleLabel: (selected) ->
          if selected && 'id' of selected
            selected.title
          else
            defaultLabel
        fieldName: $dropdown.data('field-name')
        text: (milestone) ->
          milestone.title
        id: (milestone) ->
          if !useId
            milestone.name
          else
            milestone.id
        isSelected: (milestone) ->
          milestone.name is selectedMilestone
        hidden: ->
          $selectbox.hide()
          $value.show()
        clicked: (selected) ->
          if $dropdown.hasClass 'js-filter-bulk-update'
            return

          if $dropdown.hasClass('js-filter-submit')
            if selected.name?
              selectedMilestone = selected.name
            else if selected.title?
              selectedMilestone = selected.title
            else
              selectedMilestone = ''
            $dropdown.parents('form').submit()
          else
            selected = $selectbox
              .find('input[type="hidden"]')
              .val()
            data = {}
            data[abilityName] = {}
            data[abilityName].milestone_id = selected
            $loading
              .fadeIn()
            $.ajax(
              type: 'PUT'
              url: issueUpdateURL
              data: data
            ).done (data) ->
              $loading.fadeOut()
              $selectbox.hide()
              $milestoneLink = $value
                      .show()
                      .find('a')
              if data.milestone?
                data.milestone.namespace = _this.currentProject.namespace
                data.milestone.path = _this.currentProject.path
                $value.html(milestoneLinkTemplate(data.milestone))
              else
                $value.html(milestoneLinkNoneTemplate)
      )
