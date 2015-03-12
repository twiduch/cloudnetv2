m = require 'mithril'

window.flashMessage = m.prop()
window.flashMessage('No flash message')

FrontController = require 'controllers/front'

Views = {
  'header': require 'views/layout/header'
  'footer': require 'views/layout/footer'
  'front': require 'views/front'
}

viewWithLayout = (controllerInstance) ->
  [
    Views.header(controllerInstance)
    Views[controllerInstance.constructor.view](controllerInstance)
    Views.footer(controllerInstance)
  ]

entryPoint = (Controller) ->
  controller: Controller
  view: viewWithLayout


m.route.mode = "pathname"
m.route(
  document.getElementById('container'), "/",
  {
    '/': entryPoint(FrontController)
  }
)
