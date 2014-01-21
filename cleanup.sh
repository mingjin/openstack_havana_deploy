source ./setup.conf

function clear_databases() {
  for i in keystone glance nova cinder ovs_neutron ceilometer heat
  do 
    mysql -uroot -p${mysql_pass} -e "drop database if exists $i;"
  done
}

clear_databases
