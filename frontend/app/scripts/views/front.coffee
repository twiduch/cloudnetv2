m = require 'mithril'

module.exports = (controller) ->
  if controller.datacentres()
    datacentre_count = controller.datacentres().length
  else
    datacentre_count = '<unknown>'

  [
    m 'h1', 'API',
      m 'sup', 'beta'
    m '.small-12.medium-6.columns',
      m 'strong',
        m 'a' , { href: 'https://cloud.net' }, 'Cloud.net'
        ' is a consumer-friendly interface to the '
        m 'a' , { href: 'http://onapp.com/federation' }, 'OnApp Federation'
        ',  a global network of wholesale clouds.'
      m 'p'
      m 'p',
        'We are making available an early realease to the Cloud.net API. '
        'Once you register we will manually validate your account and provide you with an API key. '
        'Detailed API documentation with examples is available '
        m 'a', { href: window.location.href.replace('www', 'doc') }, 'here'
        '.'
      m 'p',
        "There are currently #{datacentre_count} Federation datacentres available from around the world."
    m 'code.small-12.medium-6.columns',
      m 'div', '$ curl -X POST -d "template=123" "http://api.cloud.net/servers"'
      m 'p'
      m 'div', m.trust '
        { <br />
        &nbsp;&nbsp;"id": "564513b66266380008000000", <br />
        &nbsp;&nbsp;"created_at": "2015-11-12T22:33:26.779+00:00", <br />
        &nbsp;&nbsp;"updated_at": "2015-11-12T22:33:26.779+00:00", <br />
        &nbsp;&nbsp;"name": "My Server", <br />
        &nbsp;&nbsp;"hostname": "my-server", <br />
        &nbsp;&nbsp;"memory": 512, <br />
        &nbsp;&nbsp;"cpus": 1, <br />
        &nbsp;&nbsp;"disk_size": 20, <br />
        &nbsp;&nbsp;"state": "building", <br />
        &nbsp;&nbsp;"ip_address": "1.2.3.4", <br />
        &nbsp;&nbsp;"root_password": "abc123", <br />
        &nbsp;&nbsp;"template": { <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"id": "123", <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"label": "Debian 6.0 x64 LAMP", <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"os": "linux", <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"os_distro": "ubuntu", <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"min_memory_size": 128, <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"min_disk_size": 5, <br />
        &nbsp;&nbsp;&nbsp;&nbsp;"price": 0 <br />
        &nbsp;&nbsp;}, <br />
        }
      '
  ]
