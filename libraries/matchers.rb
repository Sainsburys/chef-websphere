if defined?(ChefSpec)

  # websphere_dmgr
  def create_websphere_dmgr(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_dmgr, :create, resource_name)
  end

  def start_websphere_dmgr(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_dmgr, :start, resource_name)
  end

  def stop_websphere_dmgr(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_dmgr, :stop, resource_name)
  end

  def delete_websphere_dmgr(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_dmgr, :delete, resource_name)
  end

  def sync_websphere_dmgr(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_dmgr, :sync_all, resource_name)
  end

  # websphere_profile
  def create_websphere_profile(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_profile, :create, resource_name)
  end

  def federate_websphere_profile(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_profile, :federate, resource_name)
  end

  def start_websphere_profile(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_profile, :start, resource_name)
  end

  def stop_websphere_profile(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_profile, :stop, resource_name)
  end

  def delete_websphere_profile(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_profile, :delete, resource_name)
  end

  # websphere_cluster
  def create_websphere_cluster(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster, :create, resource_name)
  end

  def delete_websphere_cluster(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster, :delete, resource_name)
  end

  def start_websphere_cluster(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster, :start, resource_name)
  end

  def ripple_start_websphere_cluster(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster, :ripple_start, resource_name)
  end

  # websphere_cluster_member
  def create_websphere_cluster_member(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster_member, :create, resource_name)
  end

  def start_websphere_cluster_member(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster_member, :start, resource_name)
  end

  def delete_websphere_cluster_member(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_cluster_member, :delete, resource_name)
  end

  # websphere_app
  def deploy_to_cluster_websphere_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_app, :deploy_to_cluster, resource_name)
  end

  def deploy_to_server_websphere_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_app, :deploy_to_server, resource_name)
  end

  def deploy_to_cluster_websphere_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_app, :deploy_to_cluster, resource_name)
  end

  def start_websphere_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_app, :start, resource_name)
  end

  def stop_websphere_app(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_app, :stop, resource_name)
  end

  # websphere_ihs
  def create_websphere_ihs(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_ihs, :create, resource_name)
  end

  def delete_websphere_ihs(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_ihs, :delete, resource_name)
  end

  def start_websphere_ihs(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_ihs, :start, resource_name)
  end

  def stop_websphere_ihs(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_ihs, :stop, resource_name)
  end

  def restart_websphere_ihs(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_ihs, :restart, resource_name)
  end

  # IBM certificates
  def create_ibm_certificate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ibm_cert, :create, resource_name)
  end

  def extract_ibm_certificate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ibm_cert, :extract, resource_name)
  end

  def add_ibm_certificate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ibm_cert, :add, resource_name)
  end

  def import_ibm_certificate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ibm_cert, :import, resource_name)
  end

  def make_default_ibm_certificate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ibm_cert, :set_default, resource_name)
  end

  # JMS
  def create_jms_provider(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_jms_provider, :create, resource_name)
  end

  def create_jms_conn_factory(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:websphere_jms_conn_factory, :create, resource_name)
  end
end
