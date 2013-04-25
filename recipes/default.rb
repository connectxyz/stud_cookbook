#
# Cookbook Name:: stud
# Recipe:: default
#
# Copyright 2012, CX Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "runit"
include_recipe "git"
include_recipe "build-essential"

package "libssl-dev"
package "libev-dev"

user node[:stud][:user]
group node[:stud][:group]

ssl_cert_and_key = data_bag_item("ssl_certificates", node.chef_environment)

template "/etc/cert.key" do
  source "key.erb"
  owner "root"
  group "root"
  mode 0600
  variables(:key => ssl_cert_and_key['private_key'])
end

template "/etc/cert.pem" do
  source "pem.erb"
  owner "root"
  group "root"
  mode 0600
  variables(:cert => ssl_cert_and_key['certificate'], :key => ssl_cert_and_key['private_key'])
end

execute "install-stud" do
  cwd "#{Chef::Config[:file_cache_path]}/stud"
  command "make install"
  creates "#{node[:stud][:dst_dir]}/stud"
  user "root"
  action :nothing
  only_if { node['haproxy']['build'] }
end

execute "workaround-stupid-chef-permissions" do
  cwd "#{Chef::Config[:file_cache_path]}"
  command "chmod 0777 ."
  user "root"
  action :nothing
  notifies :run, "service[install-stud]", :immediately
  only_if { node['haproxy']['build'] }
end


execute "make-stud" do
  cwd "#{Chef::Config[:file_cache_path]}/stud"
  command "make"
  creates "stud"
#  user node[:stud][:user]
  action :nothing
  notifies :run, "service[workaround-stupid-chef-permissions]", :immediately
  only_if { node['haproxy']['build'] }
end

git "#{Chef::Config[:file_cache_path]}/stud" do
    repository node[:stud][:repo] 
    reference node[:stud][:branch_tag]
    action :sync
#    user node[:stud][:user]
    notifies :run, "service[make-stud", :immediately
end


runit_service "stud"
