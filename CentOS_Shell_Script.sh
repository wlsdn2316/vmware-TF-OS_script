#!/bin/bash
##################################################################
# Jinwoo JOO - 2022.09.06 - Version 1.0 
##################################################################

echo -e "============================================================"    # echo -e : 특수문자 \n 등 적용
echo -e "                [Centos Shell script]"
echo -e "============================================================"
echo -e "============================================================"
echo -e "                [항목을 선택하세요]"
echo -e "============================================================"
echo -e "                [1.네트워크 설정]"
echo -e "                [2.LVM 설정]"
echo -e "                [3.VMware Tools 설치]"
echo -e "                [4.Node_exporter 설치]"
echo -e "                [5.파티션 용량 증가]"
echo -e "============================================================"

read CASE_CHECK_1

case "$CASE_CHECK_1" in
	'1')
        echo -e "============================================================"
        echo -e "                [1.네트워크 설정]"
        echo -e "============================================================"  
        echo -e " IP 입력 "
        read IP
        echo -e " NETMASK 입력 "
        read NETMASK
        echo -e " GATEWAY 입력 "
        read GATEWAY
        echo -e " DNS 입력 "
        read DNS

        sed -i 's/PROXY_METHOD=none/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/BROWSER_ONLY=no/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/BOOTPROTO=dhpc/'BOOTPROTO=static'/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/DEFROUTE=yes/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/IPV4_FAILURE_FATAL=no/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/IPV6INIT=yes/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/IPV6_AUTOCONF=yes/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/IPV6_DEFROUTE=yes/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/IPV6_FAILURE_FATAL=no/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/IPV6_ADDR_GEN_MODE=stable-privacy/''/' /etc/systemconfig/network-scripts/ifcfg-ens192
        sed -i 's/ONBOOT=no/'ONBOOT=yes'/' /etc/systemconfig/network-scripts/ifcfg-ens192
        
        echo IPADDR='$IP' >> /etc/systemconfig/network-scripts/ifcfg-ens192
        echo NETMASK='$NETMASK' >> /etc/systemconfig/network-scripts/ifcfg-ens192
        echo GATEWAY='$GATEWAY' >> /etc/systemconfig/network-scripts/ifcfg-ens192
        echo DNS1='$DNS' >> /etc/systemconfig/network-scripts/ifcfg-ens192

        sed -i '/^$/d' /etc/systemconfig/network-scripts/ifcfg-ens192                      #빈 라인 지우고 출력
    
        systemctl restart network
        
        ;;

    '2')
        echo -e "============================================================"
        echo -e "                [2.LVM 설정]"
        echo -e "============================================================"  
        
        echo "LVM 대상 파티션 입력 ex) /dev/sdb "
        read LVMPARTITION

        echo -e `fdisk $LVMPARTITION` | echo n; echo p; echo 1; echo \n; echo \n; echo t; echo 8e; echo wq;
        
        echo `pvcreate $LVMPARTITION`
        echo `vgextend centos $LVMPARTITION`
        lvcreate -n home -l 100%FREE centos
        mkfs.xfs /dev/mapper/centos-home
                                        
        echo "/dev/mapper/centos-home home                    xfs     defaults         0 0" >> /etc/vstab   
        mount -a
        df -h
        
        ;;

    '3')
        echo -e "============================================================"
        echo -e "                [3.VMware Tools 설치]"
        echo -e "============================================================"  
        
        echo "VMware Tools 설치:  "
        echo "Tool Mount 여부: (yes|no)" 
        read $CONFIRM_PROGRESS
        
        if ["$CONFIRM_PROGRESS" == "yes" -o "$CONFIRM_PROGRESS" == "Yes" -o "$CONFIRM_PROGRESS" == "YES" -o "$CONFIRM_PROGRESS" == "y" -o "$CONFIRM_PROGRESS" == "Y" -o]; then
            echo "VMware Tools 설치 시작  "
            mount /dev/sr0 /mnt
            tar zxf /mnt/VMwareTools-10.3.23-17030940.tar.gz -C /tmp
            ./tmp/vmware-tools-distrib/vmware-install.pl | echo yes; echo yes
            
            #rm -rf /tmp/vm*
        else
            echo "취소 했습니다" && exit
        fi

        ;;

    '4')
        echo -e "============================================================"
        echo -e "                [4.Node_exporter 설치]"
        echo -e "============================================================"  

        #압축해제 및 스크립트 파일 이동
        wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz 
        tar -xvzf node_exporter-0.18.1.linux-amd64.tar.gz
        mv /root/node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin/
        
        #서비스 등록 파일 생성
        touch /etc/systemd/system/node_exporter.service
        echo -e "#########################" >> /etc/systemd/system/node_exporter.service
        echo -e "[Unit]" >> /etc/systemd/system/node_exporter.service
        echo -e "Description=Node Exporter" >> /etc/systemd/system/node_exporter.service
        echo -e "After=network.target" >> /etc/systemd/system/node_exporter.service
        echo -e "\n" >> /etc/systemd/system/node_exporter.service
        echo -e "[Service]" >> /etc/systemd/system/node_exporter.service
        echo -e "User=root" >> /etc/systemd/system/node_exporter.service
        echo -e "Group=root" >> /etc/systemd/system/node_exporter.service
        echo -e "Type=simple" >> /etc/systemd/system/node_exporter.service
        echo -e "ExecStart=/usr/local/bin/node_exporter" >> /etc/systemd/system/node_exporter.service
        echo -e "\n" >> /etc/systemd/system/node_exporter.service
        echo -e "[Install]" >> /etc/systemd/system/node_exporter.service
        echo -e "WantedBy=multi-user.target" >> /etc/systemd/system/node_exporter.service

        #Daemon reload
        systemctl daemon-reload
        
        #firewall open
        firewall-cmd --add-port=9100/tcp--permanent
        firewall-cmd --reload
        
        #start node-exporter
        systemctl start node_exporter
        systemctl enable node_exporter
        systemctl status node_exporter
        curl localhost:9100/metrics

        
        echo -e "설치 완료. 프로메테우스 서버에서 target 추가 필요"
        ;;

    '5')
        echo -e "============================================================"
        echo -e "                [5.파티션 용량 증가]"
        echo -e "============================================================"    
        
        echo -e "      용량 증가시킬 파티션 입력 ex) /dev/sda "    
        read PARTITION 
        echo -e "      용량 증가시킬 파티션 번호 입력 ex) 1,2,3 "
        read PARTITIONNUMBER
        echo -e "      용량 증가시킬 LV 경로 입력 ex) /dev/mapper/centos-root "
        read LVDIRECTORY
            
        yum update -y
        yum install cloud-utils-growpart -y
        growpart $PARTITION $PARTITIONNUMBER
        pvresize $PARTITION$PARTITIONNUMBER
        lvextend -r -l +100%FREE $LVDIRECTORY
        xfs_growfs $LVDIRECTORY
                
        ;;
    *)
        echo "잘못 선택했습니다."
        ;;        
esac








echo -e " IP 입력 "
read DB_ENDPOINT

echo -e " NETMASK입력 "
read DB_MASTER

echo -e " GATEWAY입력 "
read DB_MASTER

echo -e " DNS 입력 "
read DB_PASSWORD

sudo sed -i 's/jjwmasterdb.chabsh0zrlyl.ap-northeast-2.rds.amazonaws.com/'$DB_ENDPOINT'/' /server/was/instances/center/conf/server.xml
sudo sed -i 's/jinwoo/'$DB_MASTER'/' /server/was/instances/center/conf/server.xml
sudo sed -i 's/jt201wdb/'$DB_PASSWORD'/' /server/was/instances/center/conf/server.xml
sudo yum install -y java-1.8.0-openjdk-devel.x86_64
sudo yum install -y mysql
sudo echo JAVA_HOME=/etc/alternatives/java_sdk >> /etc/profile 
sudo echo 'CLASSPATH=.:$JAVA_HOME/lib/tools.jar' >> /etc/profile 
sudo echo PATH='$PATH:$JAVA_HOME/bin' >> /etc/profile 
sudo echo CATALINA_HOME=/server/was/tomcat8 >> /etc/profile 
sudo echo export JAVA_HOME CLASSPATH PATH CATALINA_HOME >> /etc/profile 
sudo echo 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib' >> /etc/profile 
sudo echo export LD_LIBRARY_PATH >> /etc/profile
sudo useradd tomcat
sudo chown -R tomcat:tomcat /server
echo `mysql -u$DB_MASTER -p$DB_PASSWORD -h $DB_ENDPOINT < /alldatabases_2021-01-13.sql`
su - tomcat -c /server/was/launcher/startup_center.sh