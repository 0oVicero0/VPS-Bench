#!/bin/bash

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

Clean() {
rm -rf /tmp/test
rm -rf test_*
echo ""
}

pre_test() {
    [ -f "/usr/bin/speedtest" ] && return
    wget --no-check-certificate -q -O /usr/local/bin/speedtest_cli.py "https://github.com/0oVicero0/VPS-TEST/raw/master/speedtest_cli.py" 
    [ -f "/usr/local/bin/speedtest_cli.py" ] && chmod 755 /usr/local/bin/speedtest_cli.py && chmod +x /usr/local/bin/speedtest_cli.py
    [ -f "/usr/local/bin/speedtest_cli.py" ] && ln -sf /usr/local/bin/speedtest_cli.py /usr/bin/speedtest
}

speed_test() {
    [ ! -f "/usr/bin/speedtest" ] && exit 1
    TMP="/tmp/test"
    [ -f "$TMP" ] && rm -rf "$TMP"
    echo -e "Local ISP(SpeedTest)\tLatency\t\tDownload\tUpload"
    speedtest --bytes --server 3633 >> $TMP && HostName="ChinaTelecom/Shanghai" && speed_read
    speedtest --bytes --server 5083 >> $TMP && HostName="ChinaUnicom /Shanghai" && speed_read
    speedtest --bytes --server 4515 >> $TMP && HostName="ChinaMobile /Shenzhen" && speed_read
}

speed_read() {
[ -f "$TMP" ] && DL=`awk -F 'Download: ' '{ print $2 }' $TMP|tr -d '\n'`
[ -f "$TMP" ] && UL=`awk -F 'Upload: ' '{ print $2 }' $TMP|tr -d '\n'`
[ -f "$TMP" ] && LY=`awk -F ']: ' '{ print $2 }' $TMP|tr -d '\n'`
echo -e "\e[32m$HostName\t\e[33m$LY\t\e[31m$DL\t\e[31m$UL\e[0m"
[ -f "$TMP" ] && rm -rf "$TMP"
}

io_test() {
    (LANG=en_US dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

Clean;
    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( free -m | awk '/Mem/ {print $2}' )
    swap=$( free -m | awk '/Swap/ {print $2}' )
    disk=$( df -h |awk '/rootfs/{ print $2 }' )
    fred=$( df -h |awk '/rootfs/{ print $4 }' )
        usdp=$( df -h |awk '/rootfs/{ print $5 }' )
    up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
    load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    opsy=$( get_opsy )
    arch=$( uname -m )
    lbit=$( getconf LONG_BIT )
    kern=$( uname -r )
    ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )

    clear
    next
    echo "CPU model            : $cname"
    echo "Number of cores      : $cores"
    echo "CPU frequency        : $freq MHz"
    echo "Total RAM/SWAP       : $tram MB/$swap MB"
    echo "Disk capactiy        : $fred/$disk - $usdp"
    echo "System uptime        : $up"
    echo "Load average         : $load"
    echo "OS                   : $opsy"
    echo "Arch                 : $arch ($lbit Bit)"
    echo "Kernel               : $kern"
next

    io1=$( io_test )
    echo -ne "I/O speed   : $io1"
    io2=$( io_test )
    echo -ne "     $io2"
    io3=$( io_test )
    echo -ne "     $io3\n"
    ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
    [ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
    ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
    [ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
    ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
    [ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
    ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
    ioavg=$( awk 'BEGIN{print '$ioall'/3}' )
    echo "I/O Average : $ioavg MB/s"
next
    
    [ -z `which python` ] && [ -z `which python3` ] && Clean && exit 1
    pre_test && speed_test && next && Clean && exit 0
