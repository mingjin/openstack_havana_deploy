#!/usr/bin/env bash

# --------------------------------------------------------------------------------------
# install neutron
# --------------------------------------------------------------------------------------
function allinone_neutron_setup() {
  # install packages
  install_package neutron-server neutron-plugin-openvswitch neutron-plugin-openvswitch-agent dnsmasq neutron-dhcp-agent neutron-l3-agent neutron-lbaas-agent

  # create database for neutron
  mysql -u root -p${mysql_pass} -e "create database ovs_neutron;"
  mysql -u root -p${mysql_pass} -e "grant all on ovs_neutron.* to '${db_neutron_user}'@'%' identified by '${db_neutron_pass}';"

  # set configuration files
  setconf infile:$base_dir/conf/etc.neutron/metadata_agent.ini \
    outfile:/etc/neutron/metadata_agent.ini \
    "<controller_node_ip>:127.0.0.1" "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}" \
    "<nova_ip>:${nova_ip}"
  setconf infile:$base_dir/conf/etc.neutron/api-paste.ini \
    outfile:/etc/neutron/api-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"
  setconf infile:$base_dir/conf/etc.neutron/l3_agent.ini \
    outfile:/etc/neutron/l3_agent.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<controller_node_pub_ip>:${controller_node_pub_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"

  cp $base_dir/conf/etc.neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini

  setconf infile:$base_dir/conf/etc.neutron/neutron.conf \
    outfile:/etc/neutron/neutron.conf \
    "<controller_node_ip>:${controller_node_ip}" "<db_neutron_user>:${db_neutron_user}" \
    "<db_neutron_pass>:${db_neutron_pass}"

  if [[ "${network_type}" = 'gre' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<neutron_ip>:${neutron_ip}" "<db_neutron_user>:${db_neutron_user}" \
      "<db_neutron_pass>:${db_neutron_pass}"
  elif [[ "${network_type}" = 'vlan' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<db_neutron_user>:${db_neutron_user}" "<db_neutron_pass>:${db_neutron_pass}"
  else
    echo "network_type must be 'vlan' or 'gre'."
    exit 1
  fi
    
  # restart processes
  restart_service neutron-server
  restart_service neutron-plugin-openvswitch-agent
  restart_service neutron-dhcp-agent
  restart_service neutron-l3-agent
}

# --------------------------------------------------------------------------------------
# install neutron for controller node
# --------------------------------------------------------------------------------------
function controller_neutron_setup() {
  # install packages
  install_package neutron-server neutron-plugin-openvswitch
  # create database for neutron
  mysql -u root -p${mysql_pass} -e "create database ovs_neutron;"
  mysql -u root -p${mysql_pass} -e "grant all on ovs_neutron.* to '${db_neutron_user}'@'%' identified by '${db_neutron_pass}';"

  # set configuration files
  if [[ "${network_type}" = 'gre' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<neutron_ip>:${neutron_ip}" "<db_neutron_user>:${db_neutron_user}" \
      "<db_neutron_pass>:${db_neutron_pass}"
  elif [[ "${network_type}" = 'vlan' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<db_neutron_user>:${db_neutron_user}" "<db_neutron_pass>:${db_neutron_pass}"
  else
    echo "network_type must be 'vlan' or 'gre'."
    exit 1
  fi
 
  setconf infile:$base_dir/conf/etc.neutron/api-paste.ini \
    outfile:/etc/neutron/api-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"
  setconf infile:$base_dir/conf/etc.neutron/neutron.conf \
    outfile:/etc/neutron/neutron.conf \
    "<controller_node_ip>:${controller_node_ip}" "<db_neutron_user>:${db_neutron_user}" \
    "<db_neutron_pass>:${db_neutron_pass}"

  # restart process
  restart_service neutron-server
}

# --------------------------------------------------------------------------------------
# install neutron for network node
# --------------------------------------------------------------------------------------
function network_neutron_setup() {
  # install packages
  install_package mysql-client
  install_package neutron-plugin-openvswitch-agent neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent neutron-lbaas-agent

  # set configuration files
  setconf infile:$base_dir/conf/etc.neutron/metadata_agent.ini \
    outfile:/etc/neutron/metadata_agent.ini \
    "<controller_node_ip>:${controller_node_ip}" \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}#" \
    "<nova_ip>:${nova_ip}"
  setconf infile:$base_dir/conf/etc.neutron/api-paste.ini \
    outfile:/etc/neutron/api-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"
  setconf infile:$base_dir/conf/etc.neutron/l3_agent.ini \
    outfile:/etc/neutron/l3_agent.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<controller_node_pub_ip>:${controller_node_pub_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"
  setconf infile:$base_dir/conf/etc.neutron/neutron.conf \
    outfile:/etc/neutron/neutron.conf \
    "<controller_node_ip>:${controller_node_ip}"
  
  cp $base_dir/conf/etc.neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
  cp $base_dir/conf/etc.neutron/lbaas_agent.ini /etc/neutron/lbaas_agent.ini

  if [[ "${network_type}" = 'gre' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<neutron_ip>:${network_node_ip}" "<db_neutron_user>:${db_neutron_user}" \
      "<db_neutron_pass>:${db_neutron_pass}"
  elif [[ "${network_type}" = 'vlan' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<db_neutron_user>:${db_neutron_user}" "<db_neutron_pass>:${db_neutron_pass}"
  else
    echo "network_type must be 'vlan' or 'gre'."
    exit 1
  fi

  setconf infile:$base_dir/conf/etc.neutron/api-paste.ini \
    outfile:/etc/neutron/api-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"
  setconf infile:$base_dir/conf/etc.neutron/neutron.conf \
    outfile:/etc/neutron/neutron.conf \
    "<controller_node_ip>:${controller_node_ip}" "<db_neutron_user>:${db_neutron_user}" \
    "<db_neutron_pass>:${db_neutron_pass}"

  # restart processes
  cd /etc/init.d/; for i in $( ls neutron-* ); do sudo service $i restart; done
}

function compute_neutron_setup() {
  install_package neutron-plugin-openvswitch-agent neutron-lbaas-agent

  # set configuration files
  if [[ "${network_type}" = 'gre' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.gre \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<neutron_ip>:${compute_node_ip}" "<db_neutron_user>:${db_neutron_user}" \
      "<db_neutron_pass>:${db_neutron_pass}"
  elif [[ "${network_type}" = 'vlan' ]]; then
    setconf infile:$base_dir/conf/etc.neutron.plugins.openvswitch/ovs_neutron_plugin.ini.vlan \
      outfile:/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
      "<db_ip>:${db_ip}" "<neutron_ip>:${neutron_ip}" "<db_neutron_user>:${db_neutron_user}" \
      "<db_neutron_pass>:${db_neutron_pass}"
  else
    echo "network_type must be 'vlan' or 'gre'."
    exit 1
  fi

  setconf infile:$base_dir/conf/etc.neutron/neutron.conf \
    outfile:/etc/neutron/neutron.conf \
    "<controller_node_ip>:${controller_node_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}" \
    "<db_neutron_user>:${db_neutron_user}" \
    "<db_neutron_pass>:${db_neutron_pass}"

  # restart ovs agent
  service neutron-plugin-openvswitch-agent restart
}

# --------------------------------------------------------------------------------------
# create network via neutron
# --------------------------------------------------------------------------------------
function create_network() {

  # check exist 'router-demo'
  router_check=$(neutron router-list | grep "router-demo" | get_field 1)
  if [[ "$router_check" == "" ]]; then
    echo "router does not exist." 
    # create internal network
    tenant_id=$(keystone tenant-list | grep " service " | get_field 1)
    int_net_id=$(neutron net-create --tenant-id ${tenant_id} int_net | grep ' id ' | get_field 2)
    # create internal sub network
    int_subnet_id=$(neutron subnet-create --tenant-id ${tenant_id} --name int_subnet --ip_version 4 --gateway ${int_net_gateway} ${int_net_id} ${int_net_range} | grep ' id ' | get_field 2)
    neutron subnet-update ${int_subnet_id} list=true --dns_nameservers 8.8.8.8 8.8.4.4
    # create internal router
    int_router_id=$(neutron router-create --tenant-id ${tenant_id} router-demo | grep ' id ' | get_field 2)
    int_l3_agent_id=$(neutron agent-list | grep ' l3 agent ' | get_field 1)
    neutron router-interface-add ${int_router_id} ${int_subnet_id}
    # create external network
    ext_net_id=$(neutron net-create --tenant-id ${tenant_id} ext_net -- --router:external=true | grep ' id ' | get_field 2)
    # create external sub network
    neutron subnet-create --tenant-id ${tenant_id} --name ext_subnet --gateway=${ext_net_gateway} --allocation-pool start=${ext_net_start},end=${ext_net_end} ${ext_net_id} ${ext_net_range} -- --enable_dhcp=false
    # set external network to demo router
    neutron router-gateway-set ${int_router_id} ${ext_net_id}
  else
    echo "router exist. you don't need to create network."
  fi
}

# --------------------------------------------------------------------------------------
# install openvswitch
# --------------------------------------------------------------------------------------
function openvswitch_setup() {
  install_package openvswitch-switch openvswitch-datapath-dkms
  # create bridge interfaces
  ovs-vsctl add-br br-int
  ovs-vsctl add-br br-eth1
  if [[ "$1" = "network" ]]; then
    ovs-vsctl add-port br-eth1 ${datanetwork_nic_network_node}
  fi
  ovs-vsctl add-br br-ex
  ovs-vsctl add-port br-ex ${publicnetwork_nic_network_node}
}

function compute_openvswitch_setup() {
  install_package openvswitch-switch

  ovs-vsctl add-br br-int
  ovs-vsctl add-br br-eth1
  ovs-vsctl add-port br-eth1 ${datanetwork_nic_compute_node}
}

function scgroup_allow() {
  # switch to 'demo' user
  # we will use 'demo' user to access each api and instances, so it switch to 'demo'
  # user for security group setup.
  export SERVICE_TOKEN=${service_token}
  export OS_TENANT_NAME=service
  export OS_USERNAME=${demo_user}
  export OS_PASSWORD=${demo_password}
  export OS_AUTH_URL="http://${keystone_ip}:5000/v2.0/"
  export SERVICE_ENDPOINT="http://${keystone_ip}:35357/v2.0"

  # add ssh, icmp allow rules which named 'default'
  neutron security-group-rule-create --protocol icmp --direction ingress default
  neutron security-group-rule-create --protocol tcp --port-range-min 22 --port-range-max 22 --direction ingress default
  neutron security-group-rule-list

  # switch to 'admin' user
  # this script need 'admin' user, so turn back to admin.
  export SERVICE_TOKEN=${service_token}
  export OS_TENANT_NAME=${os_tenant_name}
  export OS_USERNAME=${os_username}
  export OS_PASSWORD=${os_password}
  export OS_AUTH_URL="http://${keystone_ip}:5000/v2.0/"
  export SERVICE_ENDPOINT="http://${keystone_ip}:35357/v2.0"
}

