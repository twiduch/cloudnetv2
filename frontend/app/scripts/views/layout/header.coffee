m = require 'mithril'
module.exports = (controller) ->
  m 'header.row', [
    m 'span.small-6.columns',
      m "a[href='/'].logo", { config: m.route }, [
        m 'img', { src: '/assets/images/cloudnet_big.png' }
        m '.span.cloudnet', 'cloud.net'
      ]
    m 'span.account-menu.small-6.columns',
      if controller.currentUser()
        [
          m 'span.logged-in-user',
            m 'p', "Logged in as #{controller.currentUser().full_name}"
            m "a[href='/dashboard']", { config: m.route }, 'Dashboard'
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
  ]
