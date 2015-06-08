require 'main'
m = require 'mithril'

describe 'Front page', ->
  it 'should render the front page', ->
    SpecHelpers.ajaxResponse( [{
      "_id":4,
      "label": "Cloud.net Budget UK London Zone",
      "coords": [1, 2],
      "templates": [{
        "_id":32,
        "datacentre_id":4,
        "label": "Arch Linux 2012.08 x86"
      }]
    }] )

    m.route('/')
    dcTitle = mock.document.body.childNodes[1].childNodes[0].nodeValue
    expect(dcTitle).toEqual 'Cloud.net Budget UK London Zone (1,2)'
