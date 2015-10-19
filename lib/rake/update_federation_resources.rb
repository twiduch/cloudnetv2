# Fetch the available datacentres and templates currently on the Federation
class UpdateFederationResources
  include Cloudnet::Logger

  # GP coords [lat, long] for
  COORDS_FOR_DATACENTRES = {
    'Cloud.net Budget US Dallas Zone' => [32.7767, 96.7970]
  }

  def self.run
    new.run
  end

  def initialize
    @api = OnappAPI.admin_connection
  end

  def run
    logger.info 'Running update to get meta data from datacentres'
    @store = @api.template_store.get
    loop_through_datacentres
  end

  def loop_through_datacentres
    @store.each do |datacentre|
      next unless on_federation? datacentre
      upsert_datacentre datacentre
      loop_through_templates datacentre
    end
  end

  def on_federation?(datacentre)
    return false unless datacentre['hypervisor_group_id']
    # The clue is the 'remote' tag on a template, so peek at the first template
    first_template = datacentre['relations'].first
    virtualization = first_template['image_template']['virtualization']
    return false unless virtualization
    virtualization.split(',').include? 'remote'
  end

  def loop_through_templates(datacentre)
    templates = datacentre['relations']
    templates.each do |template|
      upsert_template template, datacentre
    end
  end

  def upsert_datacentre(datacentre)
    Datacentre.new(
      id: datacentre['hypervisor_group_id'],
      label: datacentre['label'],
      coords: COORDS_FOR_DATACENTRES[datacentre['label']]
    ).upsert
  end

  # rubocop:disable Metrics/MethodLength
  def upsert_template(template, datacentre)
    details = template['image_template']
    Template.new(
      id: template['template_id'],
      datacentre: datacentre['hypervisor_group_id'],
      label: details['label'],
      os: details['operating_system'],
      os_distro: details['operating_system_distro'],
      min_memory_size: details['min_memory_size'],
      min_disk_size: details['min_disk_size'],
      price: template['price']
    ).upsert
  end
end
