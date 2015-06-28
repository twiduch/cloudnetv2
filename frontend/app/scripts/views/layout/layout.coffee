m = require 'mithril'

module.exports = (content) ->
  (controller) ->
    [
      m 'header', [
        m "a[href='/'].logo", { config: m.route }, 'Cloud.net'
        if controller.currentUser()
          [
            m 'span.logged-in-user', [
              'Logged in as '
              m "a[href='/dashboard']", { config: m.route }, "#{controller.currentUser().full_name}"
            ]
            m 'span', ' | '
            m "a[href='javascript:;']", {
              onclick: controller.api.logout
            }, 'Logout'
          ]
        else
          [
            m "a[href='/auth/login']", { config: m.route }, 'Login'
            m 'span', ' | '
            m "a[href='/auth/register']", { config: m.route }, 'Register'
          ]
        m 'p', controller.api.ajax.message()
      ]
      content(controller)
      m 'footer', '© 2015'
    ]
