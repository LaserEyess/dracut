#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    if ! dracut_module_included "systemd"; then
        derror "systemd-networkd needs systemd in the initramfs"
        return 1
    fi

    return 255
}

# called by dracut
depends() {
    echo "systemd kernel-network-modules"
}

installkernel() {
    return 0
}

# called by dracut
install() {
    inst_multiple -o \
        $systemdutildir/systemd-networkd \
        $systemdutildir/systemd-networkd-wait-online \
        $systemdutildir/systemd-network-generator \
        $systemdsystemunitdir/systemd-networkd-wait-online.service \
        $systemdsystemunitdir/systemd-networkd.service \
        $systemdsystemunitdir/systemd-networkd.socket \
        $systemdsystemunitdir/systemd-network-generator.service \
        $systemdutildir/network/99-default.link \
        networkctl ip resolvectl \
        $systemdutildir/systemd-timesyncd \
        $systemdutildir/systemd-resolved \
        $systemdutildir/systemd-resolve-host \
        $systemdsystemunitdir/systemd-resolved.service \
        $systemdsystemunitdir/systemd-timesyncd.service \
        $systemdsystemunitdir/time-sync.target

    inst_dir /var/lib/systemd/clock

    grep '^systemd-network:' $dracutsysrootdir/etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    grep '^systemd-network:' $dracutsysrootdir/etc/group >> "$initdir/etc/group"
    grep '^systemd-timesync:' $dracutsysrootdir/etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    grep '^systemd-timesync:' $dracutsysrootdir/etc/group >> "$initdir/etc/group"
    grep '^systemd-resolve:' $dracutsysrootdir/etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    grep '^systemd-resolve:' $dracutsysrootdir/etc/passwd >> "$initdir/etc/group"

    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_dns.so.*" \
                     {"tls/$_arch/",tls/,"$_arch/",}"libnss_mdns4_minimal.so.*" \
                     {"tls/$_arch/",tls/,"$_arch/",}"libnss_myhostname.so.*" \
                     {"tls/$_arch/",tls/,"$_arch/",}"libnss_resolve.so.*"

    if [[ $host_only ]]; then
        inst_multiple -o \
            /etc/systemd/timesyncd.conf \
            /etc/systemd/timesyncd.conf.d/*.conf \
            /etc/systemd/resolved.conf \
            /etc/systemd/resolved.conf.d/*.conf \
            /etc/systemd/networkd.conf \
            /etc/systemd/networkd.conf.d/*.conf
    fi

    # DNSSEC still has issues and distros who use systemd-resolved almost
    # all universially disable it by default, including Fedora, Arch, and Ubuntu
    # See Fedora's motivation's here:
    # https://fedoraproject.org/wiki/Changes/systemd-resolved#DNSSEC
    mkdir -p "$initdir/etc/systemd"
    {
        echo "[Resolve]"
        echo "DNSSEC=no"
    } >> "$initdir/etc/systemd/resolved.conf"

    ln -sf /run/systemd/resolve/stub-resolv.conf "$initdir"/etc/resolv.conf

    for i in \
        systemd-networkd-wait-online.service \
        systemd-network-generator.service \
        systemd-networkd.service \
        systemd-networkd.socket \
        systemd-timesyncd.service \
        systemd-resolved.service
    do
        systemctl -q --root "$initdir" enable "$i"
    done
}

