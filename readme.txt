# Meshr.Net

   Meshr is a free open source software for creating and popularization
   of mesh networks. The main goals of Meshr are to make Internet
   available to as much number of people as possible all over the world,
   to make communication between people free and depend only on mesh
   network members and to make free and accurate Wi-Fi positioning. To
   reach these goals it makes available easy to use zero-configuration
   cross-platform versions of Freifunk Openwrt firmwares for
   international community. Meshr is an open and independent project.
   Everyone is welcome to contribute.
   
   Software versions for different platforms including Windows are
   available now. They allow to connect to Freifunk networks and
   meshr.net free Internet gateways anonymized by TOR.

   Meshr download link for TomatoUSB:
   https://github.com/meshr-net/meshr_tomato-RT-N/releases/download/latest/meshr-tomato-rt-n_mipsel.ipk.sh
   
   Use this command to install from telnet/ssh:
   cd /opt && wget https://github.com/meshr-net/meshr_tomato-RT-N/releases/download/latest/meshr-tomato-rt-n_mipsel.ipk.sh -O m.ipk.sh && sh ./m.ipk.sh
   
### Installation requirements
 
   Meshr requires router with TomatoUSB firmware. Tested version are:
     * Tomato by Shibby MIPSR2-115 K26 USB AIO-64K with tomatoware(?)
       installed.
       

### Installation guide

    1. Telnet/ssh to your router.
    2. Change directory to location where you want to install meshr
       software. You must have write permissions to this directory and
       about 20Mb free disk space. Possible variants:
          + USB flash or sd-card is the best choice. You should run cd
            /opt to install it to /opt/meshr directory.
          + You can install it to shared drive (or nfs) if you mounted
            network drive to /cifs1 directory from Tomato web interface.
            You should run cd /cifs1 to install it to /opt/cifs1
            directory.
          + You should install it to /tmp folder if above solutions are
            not possible. You should run cd /tmp to install it to
            /tmp/meshr directory.
    3. Copy & paste this command to telnet/ssh and press Enter to run
       installation: wget
       https://github.com/meshr-net/meshr_tomato-RT-N/releases/download/l
       atest/meshr-tomato-rt-n_mipsel.ipk.sh -O m.ipk.sh && sh ./m.ipk.sh
       
   Notes:
     * Meshr installation file (i.e. meshr-tomato-rt-n_mipsel.ipk.sh) is
       self-extracting ipkg package with CONTROL/postinst script file to
       run installation after extracting.
     * Meshr changes script_fire nvram variable to enable autorun after
       reboot. It runs $meshr/install.bat boot after reboot (where $meshr
       is installation folder). If there is no install.bat anymore (USB
       drive unplugged, cifs disconnected or install folder was /tmp)
       meshr tries to download its installation file from Internet (TODO:
       or mesh network peers) and installs it to /tmp folder. AFter
       installation it looks for meshr_backup nvram variable to restore
       configuration (meshr_backup nvram variable is created
       automatically after each update or when you run ./update.bat).
     * If you want to uninstall meshr then telnet/ssh to your router,
       change directory to installation folder (for example, cd
       /opt/meshr) and copy & paste this command ./install.bat Uninstall

### Configuration

   Navigate to http://your_router_ip:8084 in your browser to configure
   meshr thru Web interface. Replace your_router_ip with your router (for
   example, http://192.168.0.1:8084).
   
   Notes:
     * Wi-fi related configuration files added to /etc folder:
          + $meshr/etc/wlan/ folder contains *.txt files for ip
            configuration settings.
          + $meshr/etc/wifi.txt file contains settings for default

### Meshr feature list

  Automatic configuration
  
   Meshr runs automatic configuration script during installation (it is
   ./defaults.bat script file in the installation folder). More info
   
  Automatic updates
  
   Meshr does checks for updates every 24 hours (it is ./update.bat
   script file). It checks release branch in git and downloads modified
   files if there are new ones. You can also run ./lib/update-master.bat
   batch file manually to update to the most recent version from master
   (pre-release) branch. It also updates ipkg software list.

### How it works?
       
Before first use

   Meshr generates default configuration after installation to create new
   meshr node (it is here ./default.bat)
    1. Meshr tries to determine your current geo-location to fill basic
       settings for you (it is here
       http://127.0.0.1:8084/luci/admin/freifunk/basics/, for router
       replace 127.0.0.1 with your router IP).
    2. You get IP-address in 10.177.0.0/16 range from meshr.net while
       installation. IP is generated automatically in
       10.177.128.1-10.177.253.255 range if there is no Internet access.
    3. Meshr is looking for known mesh networks that are available in the
       air. If it finds any it configures meshr settings to create new
       node of this network. If there is no known networks then it
       configures meshr settings to create new node of meshr.net network.
       
   Note: Additional setup is needed for Freifunk olsr mesh networks other
   than meshr (any help for integration with other mesh networks is
   welcome).
    1. Make sure correct community is selected on "Administration ->
       Freifunk -> Basic Settings" page
       http://127.0.0.1:8084/luci/admin/freifunk/basics/, for router
       replace 127.0.0.1 with your router IP
    2. Go to "Administration -> Freifunk -> Mesh Wizard" page. Select
       Interface where "Mesh IP address" is enabled and input your
       community ip address there. Press "Save & Apply" button to apply
       new settings (i.e. network and olsrd settings).
       
Everyday use

   Meshr is monitoring status of your wireless adapter (in
   ./lib/watchdog.bat)
    1. If your computer has Internet access and your wireless adapter is
       unused then meshr creates ad-hoc network and waits for users to
       connect
         1. If there is a new user connection then meshr launches on your
            computer (under linux it happens even without new user
            connection):
              1. TOR - it is socks proxy server for tunneling all new
                 user's connections to Internet through it (it is here
                 127.0.0.1:9150).
              2. meshr-splash - it is a webserver with welcome page for
                 new users (it used tcp socket like 10.177.X.X:80). It is
                 necessary to provide meshr software download link to new
                 users to enable them access to mesh networks, including
                 TOR proxy servers for anonymous Internet access.
              3. DualServer or dnsmasq (under linux) - it is DHCP and DNS
                 server in one (DualServer web interface is
                 http://127.0.0.1:6789 ). It provides IP address, default
                 gateway and DNS server for new users. This settings are
                 necessary to direct new user to your welcome page with
                 meshr software download link.
              4. olsrd - it is routing software that provides
                 connectivity between mesh nodes even if there is no
                 direct connection between them. It also advertised TOR
                 proxy servers for Internet access.
         2. If all users disconnect from your node then meshr stops TOR,
            DualServer and meshr-splash services and restores your old IP
            settings (it happens only under Windows) .
    2. If your computer has no Internet access and you are connecting to
       meshr node (wireless network with meshr.net name) then
         1. If you haven't installed meshr software then you will get
            meshr welcome page instead of any Internet page. You need to
            download and install meshr software in this case.
         2. If you have installed meshr software then you get IP-address
            from it, then meshr launches on your computer olsrd routing
            service and looks for available TOR proxy servers. Once it
            finds working one it launches (in ./lib/tor-tun.bat):
              1. badvpn-tun2socks It connects your TAP adapter with a TOR
                 proxy server from mesh network. As a result new local
                 internet gateway is created: 10.177.254.2
              2. dns2socks It creates local dns server 10.177.254.1 for
                 resolving Internet domains thru TOR socks server.
              3. Default gateway is set to 10.177.254.2 and dns is set to
                 10.177.254.1 to enable Internet access
       

### Author ###

* Yury Popov (<meshr.net[at]googlemail.com>)

This file is generated automatically from http://Meshr.Net wiki pages