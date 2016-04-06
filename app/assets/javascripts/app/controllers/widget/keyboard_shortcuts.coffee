class App.KeyboardShortcutModal extends App.ControllerModal
  authenticateRequired: true
  large: true
  head: 'Keyboard Shortcuts'
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: ->
    super
    @bind('keyboard_shortcuts_close', @close)

  content: ->
    App.view('keyboard_shortcuts')(
      areas: App.Config.get('keyboard_shortcuts')
    )

  exists: =>
    return true if @el.parents('html').length > 0
    false

class App.KeyboardShortcutWidget extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @observerKeys()

  observerKeys: =>
    navigationHotkeys = 'alt+ctrl'
    areas = App.Config.get('keyboard_shortcuts')
    for area in areas
      for item in area.content
        for shortcut in item.shortcuts
          do (shortcut) =>
            modifier = ''
            if shortcut.hotkeys
              modifier += navigationHotkeys
            if shortcut.key
              if modifier isnt ''
                modifier += '+'
              modifier += shortcut.key
              if shortcut.callback
                @log 'debug', 'bind for', modifier
                $(document).bind('keydown', modifier, (e) ->
                  e.preventDefault()
                  shortcut.callback()
                )

    App.Event.bind('global-shortcut', (e) ->
      for area in areas
        for item in area.content
          for shortcut in item.shortcuts
            if shortcut.globalEvent is e
              shortcut.callback()
    )

App.Config.set('keyboard_shortcuts', App.KeyboardShortcutWidget, 'Widgets')
App.Config.set(
  'keyboard_shortcuts',
  [
    {
      headline: 'Navigation'
      location: 'left'
      content: [
        {
          where: 'Used anywhere'
          shortcuts: [
            {
              key: 'd'
              hotkeys: true
              description: 'Dashboard'
              globalEvent: 'dashboard'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#dashboard'
            }
            {
              key: 'o'
              hotkeys: true
              description: 'Overviews'
              globalEvent: 'overview'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#ticket/view'
            }
            {
              key: 's'
              hotkeys: true
              description: 'Search'
              globalEvent: 'search'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('#global-search').focus()
            }
            {
              key: 'a'
              hotkeys: true
              description: 'Notifications'
              globalEvent: 'notification'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .js-toggleNotifications').click()
            }
            {
              key: 'n'
              hotkeys: true
              description: 'New Ticket'
              globalEvent: 'new-ticket'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#ticket/create'
            }
            {
              key: 'e'
              hotkeys: true
              description: 'Logout'
              globalEvent: 'logout'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#logout'
            }
            {
              key: 'h'
              hotkeys: true
              description: 'List of shortcuts'
              globalEvent: 'list-of-shortcuts'
              callback: =>
                if @dialog && @dialog.exists()
                  @dialog.close()
                  @dialog = false
                  return
                @dialog = new App.KeyboardShortcutModal()
            }
            {
              key: 'w'
              hotkeys: true
              description: 'Close current tab'
              globalEvent: 'close-current-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .tasks .is-active .js-close').click()
            }
            {
              key: 'tab'
              hotkeys: true
              description: 'Next in tab'
              globalEvent: 'next-in-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                scollIfNeeded = (element) ->
                  return if !element
                  return if !element.get(0)
                  element.get(0).scrollIntoView(false)
                current = $('#navigation .tasks .is-active')
                if current.get(0)
                  next = current.next()
                  if next.get(0)
                    next.find('div').first().click()
                    scollIfNeeded(next)
                    return
                prev = $('#navigation .tasks .task').first()
                if prev.get(0)
                  prev.find('div').first().click()
                  scollIfNeeded(prev)
            }
            {
              key: 'shift+tab'
              hotkeys: true
              description: 'Previous tab'
              globalEvent: 'previous-in-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                scollIfNeeded = (element) ->
                  return if !element
                  return if !element.get(0)
                  element.get(0).scrollIntoView(true)
                current = $('#navigation .tasks .is-active')
                if current.get(0)
                  prev = current.prev()
                  if prev.get(0)
                    prev.find('div').first().click()
                    scollIfNeeded(prev)
                    return
                last = $('#navigation .tasks .task').last()
                if last.get(0)
                  last.find('div').first().click()
                  scollIfNeeded(last)
            }
            {
              key: 'return'
              hotkeys: true
              description: 'Confirm/submit dialog'
              globalEvent: 'submit'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')

                # check of primary modal exists
                dialog = $('body > div.modal')
                if dialog.get(0)
                  dialog.find('.js-submit').click()
                  return

                # check of local modal exists
                dialog = $('.active.content > div.modal')
                if dialog.get(0)
                  dialog.find('.js-submit').click()
                  return

                # check ticket edit
                dialog = $('.active.content .js-attributeBar .js-submit')
                if dialog.get(0)
                  dialog.first().click()
                  return

                dialog = $('.active.content .js-submit')
                if dialog.get(0)
                  dialog.first().click()
                  return
            }
          ]
        }
        {
          where: 'Used in lists (views and results)'
          shortcuts: [
            {
              key: ['▲', '▼']
              description: 'Move up and down'
            }
            {
              key: ['◀', '▶']
              description: 'Move left and right'
            }
            {
              key: 'enter'
              description: 'Select item',
            }
          ]
        }
      ]
    }
    {
      headline: 'Translations'
      location: 'left'
      content: [
        {
          where: 'Used anywhere (admin only)'
          shortcuts: [
            {
              admin: true
              key: 't'
              hotkeys: true
              description: 'Enable/disable inline translations'
              globalEvent: 'translation-mode'
            }
          ]
        }
      ]
    }
    {
      headline: 'Tickets'
      location: 'right'
      content: [
        {
          where: 'Used when viewing a Ticket'
          shortcuts: [
            {
              key: 'm'
              hotkeys: true
              description: 'Open note box'
              globalEvent: 'article-note-open'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('.active.content .editControls .js-articleTypes [data-value="note"]').click()
                $('.active.content .article-new .articleNewEdit-body').first().focus()
            }
            {
              key: 'g'
              hotkeys: true
              description: 'Reply to last article'
              globalEvent: 'article-reply'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                lastArticleWithReply = $('.active.content .ticket-article .icon-reply').last()
                lastArticleWithReplyAll = lastArticleWithReply.parent().find('.icon-reply-all')
                if lastArticleWithReplyAll.get(0)
                  lastArticleWithReplyAll.click()
                  return
                lastArticleWithReply.click()
            }
            {
              key: 'j'
              hotkeys: true
              description: 'Set article to internal/public'
              globalEvent: 'article-internal-public'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('.active.content .editControls .js-selectInternalPublic').click()
            }
            #{
            #  key: 'm'
            #  hotkeys: true
            #  description: 'Open macro selection'
            #  globalEvent: 'macro-open'
            #  callback: ->
            #    window.location.hash = '#ticket/create'
            #}
            {
              key: 'c'
              hotkeys: true
              description: 'Update as closed'
              globalEvent: 'task-update-close'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                return if !$('.active.content .edit').get(0)
                $('.active.content .edit [name="state_id"]').val(4)
                $('.active.content .js-attributeBar .js-submit').first().click()
            }
          ]
        }

      ]
    }
    {
      headline: 'Text editing'
      location: 'right'
      content: [
        {
          where: 'Used when composing a text'
          shortcuts: [
            {
              key: 'u'
              hotkeys: true
              description: 'Format as _underlined_'
              globalEvent: 'richtext-underline'
            }
            {
              key: 'b'
              hotkeys: true
              description: 'Format as |bold|'
              globalEvent: 'richtext-bold'
            }
            {
              key: 'i'
              hotkeys: true
              description: 'Format as ||italic||'
              globalEvent: 'richtext-italic'
            }
            {
              key: 'v'
              hotkeys: true
              description: 'Format as //strikethrough//'
              globalEvent: 'richtext-strikethrough'
            }
            {
              key: 'f'
              hotkeys: true
              description: 'Removes the formatting'
              globalEvent: 'richtext-remove-formating'
            }
            {
              key: 'z'
              hotkeys: true,
              description: 'Inserts a horizontal rule'
              globalEvent: 'richtext-hr'
            }
            {
              key: 'l'
              hotkeys: true,
              description: 'Format as unordered list'
              globalEvent: 'richtext-ul'
            }
            {
              key: 'k'
              hotkeys: true,
              description: 'Format as ordered list'
              globalEvent: 'richtext-ol'
            }
            {
              key: '1'
              hotkeys: true,
              description: 'Format as h1 heading'
              globalEvent: 'richtext-h1'
            }
            {
              key: '2'
              hotkeys: true,
              description: 'Format as h2 heading'
              globalEvent: 'richtext-h2'
            }
            {
              key: '3'
              hotkeys: true,
              description: 'Format as h3 heading'
              globalEvent: 'richtext-h3'
            }
            {
              key: 'x'
              hotkeys: true,
              description: 'Removes any hyperlink'
              globalEvent: 'richtext-remove-hyperlink'
            }
          ]
        }
      ]
    }
  ]
)