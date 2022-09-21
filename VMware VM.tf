#[출처] Terraform + VM Template = 대량 배포|작성자 Patton
#ctrl k + c  모두 주석
#ctrl k + u  모두 주석해제

# Variables
variable "vsphere_domain"               {default = "dm-mgt-vcenter-1.dmvpc.local"}
variable "vsphere_user"                 {default = "jwjin"}
variable "vsphere_user_paasword"        {default = "Dream@1029!#"}

variable "data_center"                  {default = "dmvpc-datacenter"}
variable "cluster"                      {default = "compute-cluster"}
variable "workload_datastore"           {default = "ZBS"}

variable "workload_host"                {default = "dm-comp-esxi-5.dmvpc.local"}
variable "vm_network"                   {default = "cu-bookcubenetworks-seg"}	
variable "vm_template"                  {default = "TP-centos7.9"}	
variable "ip_address"                   {default = "10.105.0."}	
variable "IPnStarting"                  {default = 5}                                    #count + IPnStarting값, ip끝자리 결정
variable "VM_name_prefix"               {default = "TEST-terraform-"}
variable "VM_name_suffix"               {default = "-Copy"}
variable "nVMs"                         {default = 3}                                    #VM 생성 개수
variable "nStarting"                    {default = 0}                                    #초기 시작 숫자 변경을 위한 값
variable "ipv4_gateway"                 {default = "10.105.0.1"}  

#################################################################################################################
####                                Terraform Provider for VMware vSphere                                    ####
#################################################################################################################

provider "vsphere" {
  user                 = "jwjin"
  password             = "Dream@1029!#"
  vsphere_server       = "dm-mgt-vcenter-1.dmvpc.local"
  allow_unverified_ssl = true                                            
}

 data "vsphere_datacenter" "mark1dc" {
   name = "dmvpc-datacenter"
 }

# If you don't have any resource pools, put "Resources" after cluster name
 data "vsphere_resource_pool" "pool" {
   name          = "compute-cluster/Resources"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

 data "vsphere_compute_cluster" "cluster" {
   name          = "compute-cluster"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

data "vsphere_host" "host" {
  name          = var.workload_host                                         #"dm-comp-esxi-5.dmvpc.local"
  datacenter_id = data.vsphere_datacenter.mark1dc.id
}

 data "vsphere_datastore" "datastore" {
   name          = "ZBS"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

 data "vsphere_network" "network" {
   name          = var.vm_network                                           #"cu-bookcubenetworks-seg"
   datacenter_id = data.vsphere_datacenter.mark1dc.id
 }

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template                                           #"TP-centos7.9"
  datacenter_id = data.vsphere_datacenter.mark1dc.id
} 

#################################################################################################################
####                                               VM CREATION                                               ####
#################################################################################################################

resource "vsphere_virtual_machine" "DemoVM" {

  count            = var.nVMs  

  name             = "${var.VM_name_prefix}${format("%02d", count.index + var.nStarting)}${var.VM_name_suffix}"
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  
  num_cpus         = 2
  memory           = 4096
  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  firmware         = data.vsphere_virtual_machine.template.firmware

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk${count.index}"  # 디스크는 블록label 의 속성에 제공된 레이블로 관리됩니다 . 이는 가상 머신이 생성될 때 vSphere가 할당하는 자동 이름 지정과는 별개입니다.
    size  = 50
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.VM_name_prefix}${format("%02d", count.index + var.nStarting)}${var.VM_name_suffix}"
        domain    = "test.internal"
      }

      network_interface {
        ipv4_address    = "${var.ip_address}${count.index + var.IPnStarting}"
        ipv4_netmask    = 29
        dns_server_list = ["8.8.8.8", "8.8.4.4"]
      }
      ipv4_gateway = var.ipv4_gateway
    }
  }

}