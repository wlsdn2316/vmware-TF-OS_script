

#################################################################################################################
####                                Terraform Provider for VMware vSphere                                    ####
#################################################################################################################
#ctrl k + c  모두 주석
#ctrl k + u  모두 주석해제

provider "vsphere" {
  user                 = "jwjin"
  password             = "Dream@1029!#"
  vsphere_server       = "dm-mgt-vcenter-1.dmvpc.local"
  allow_unverified_ssl = true
}

 data "vsphere_datacenter" "mark1dc" {
   name = "dmvpc-datacenter"
 }

# data "vsphere_resource_pool" "pool" {
#   name          = "compute-cluster/dm-comp-esxi-5.dmvpc.local"
#   datacenter_id = data.vsphere_datacenter.mark1dc.id
# }

 data "vsphere_compute_cluster" "cluster" {
   name          = "compute-cluster"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

 data "vsphere_datastore" "datastore" {
   name          = "ZBS"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

 data "vsphere_network" "network" {
   name          = "cu-bookcubenetworks-seg"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

# Retrieve template information on vsphere
data "vsphere_virtual_machine" "template" {
  name          = "TP-centos7.9"
  datacenter_id = data.vsphere_datacenter.mark1dc.id
} 

#################################################################################################################
####                                               VM CREATION                                               ####
#################################################################################################################

resource "vsphere_virtual_machine" "DemoVM" {
  name             = "TEST-DemoVM"
  resource_pool_id = data.vsphere_compute_cluster.cluster.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 4096
  guest_id         = "data.vsphere_virtual_machine.template"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 30
  }
}

#변경사항 테스트