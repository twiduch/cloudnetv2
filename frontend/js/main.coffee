app = {}

# model
app.Datacentres = () ->
  m.request({method: "GET", url: "http://localhost:9292/datacentres"})

# controller
app.controller = () ->
  {
    datacentres: app.Datacentres()
  }

# view
app.view = (ctrl) ->
  [
    ctrl.datacentres().map (datacentre) -> [
      m 'h1', datacentre.label
      m 'ul', datacentre.templates.map (template) ->
        m 'li', template.label
    ]
  ]

# initialize
m.module(document.getElementById('container'), app)
