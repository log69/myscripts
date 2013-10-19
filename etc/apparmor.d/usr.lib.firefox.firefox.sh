# info: strict apparmor firefox profile
# platform: ubuntu 13.10 x64
# usage:
#   sudo cp sr.lib.firefox.firefox.sh /etc/apparmor.d
#   sudo aa-enforce /etc/apparmor.d/usr.lib.firefox.firefox.sh
# note:
#   error message boxes may pop up when running firefox
#   this is because firefox is not given access to dbus


/usr/lib/firefox/firefox.sh {

  capability sys_ptrace,

  network inet dgram,
  network inet stream,
  network inet6 dgram,
  network inet6 stream,


  /bin/dash rix,
  /bin/grep rix,
  /bin/ps rix,
  /bin/which rix,
  
  /usr/lib/firefox/plugin-container rix,

  /dev/dri/* rw,
  /dev/null rw,
  /dev/tty r,
  /dev/urandom r,
  /dev/snd/* r,
  /dev/log rw,

  /etc/drirc r,
  /etc/firefox/ r,
  /etc/firefox/** r,
  /etc/fonts/ r,
  /etc/fonts/** r,
  /etc/fstab r,
  /etc/gai.conf r,
  /etc/gnome-vfs-2.0/modules/ r,
  /etc/gnome-vfs-2.0/modules/** r,
  /etc/gnome/defaults.list r,
  /etc/host.conf r,
  /etc/hosts r,
  /etc/ld.so.cache mr,
  /etc/locale.alias r,
  /etc/localtime r,
  /etc/mailcap r,
  /etc/mime.types r,
  /etc/nsswitch.conf r,
  /etc/passwd r,
  /etc/pulse/ r,
  /etc/pulse/* r,
  /etc/sound/events/ r,
  /etc/sound/events/** r,
  /etc/vdpau_wrapper.cfg r,
  /etc/xul-ext/ r,
  /etc/xul-ext/** r,

  /home/*/ r,
  /home/*/.ICEauthority r,
  /home/*/.Xauthority r,
  /home/*/.adobe/ r,
  /home/*/.adobe/** r,
  /home/*/.cache/ rwk,
  /home/*/.cache/** rwk,
  /home/*/.config/dconf/user r,
  /home/*/.config/gtk-2.0/ r,
  /home/*/.config/gtk-2.0/** rw,
  /home/*/.config/gtk-3.0/ r,
  /home/*/.config/gtk-3.0/** rw,
  /home/*/.config/pulse/cookie rk,
  /home/*/.config/user-dirs.dirs r,
  /home/*/.fonts/ r,
  /home/*/.fonts/** r,
  /home/*/.icons/ r,
  /home/*/.icons/** r,
  /home/*/.local/share/ r,
  /home/*/.local/share/** rwk,
  /home/*/.macromedia/ r,
  /home/*/.macromedia/** rw,
  /home/*/.mozilla/ r,
  /home/*/.mozilla/** mrwk,

  /lib/lib*so* mr,
  /lib/x86_64-linux-gnu/libattr.so.* mr,
  /lib/x86_64-linux-gnu/libbz*.so.* mr,
  /lib/x86_64-linux-gnu/libc-*.so mr,
  /lib/x86_64-linux-gnu/libdbus-*.so.* mr,
  /lib/x86_64-linux-gnu/libdl-*.so mr,
  /lib/x86_64-linux-gnu/libexpat.so.* mr,
  /lib/x86_64-linux-gnu/libgcc_s.so.* mr,
  /lib/x86_64-linux-gnu/libgcrypt.so.* mr,
  /lib/x86_64-linux-gnu/libglib-*.so.* mr,
  /lib/x86_64-linux-gnu/libgpg-error.so.* mr,
  /lib/x86_64-linux-gnu/liblzma.so.* mr,
  /lib/x86_64-linux-gnu/liblzo*.so.* mr,
  /lib/x86_64-linux-gnu/libm-*.so mr,
  /lib/x86_64-linux-gnu/libnsl-*.so mr,
  /lib/x86_64-linux-gnu/libnss_compat-*.so mr,
  /lib/x86_64-linux-gnu/libnss_dns-*.so mr,
  /lib/x86_64-linux-gnu/libnss_files-*.so mr,
  /lib/x86_64-linux-gnu/libnss_nis-*.so mr,
  /lib/x86_64-linux-gnu/libpcre.so.* mr,
  /lib/x86_64-linux-gnu/libpng*.so.* mr,
  /lib/x86_64-linux-gnu/libpopt.so.* mr,
  /lib/x86_64-linux-gnu/libpthread-*.so mr,
  /lib/x86_64-linux-gnu/libresolv-*.so mr,
  /lib/x86_64-linux-gnu/librt-*.so mr,
  /lib/x86_64-linux-gnu/libselinux.so.* mr,
  /lib/x86_64-linux-gnu/libsystemd-login.so.* mr,
  /lib/x86_64-linux-gnu/libudev.so.* mr,
  /lib/x86_64-linux-gnu/libutil-*.so mr,
  /lib/x86_64-linux-gnu/libuuid.so.* mr,
  /lib/x86_64-linux-gnu/libz.so.* mr,
  /lib/x86_64-linux-gnu/libjson-*.so.* mr,
  /lib/x86_64-linux-gnu/libwrap.so.* mr,
  /lib/x86_64-linux-gnu/libssl.so.* mr,
  /lib/x86_64-linux-gnu/libcom_err.so.* mr,
  /lib/x86_64-linux-gnu/libprocps.so.* mr,
  /lib/x86_64-linux-gnu/libcrypto.so.* mr,
  /lib/x86_64-linux-gnu/libkeyutils.so.* mr,
  /lib/x86_64-linux-gnu/libcrypt-*.so mr,
  /lib/x86_64-linux-gnu/libcap.so.* mr,
  
  /proc/ r,
  /proc/*/cmdline r,
  /proc/*/fd/ r,
  /proc/*/maps r,
  /proc/*/mountinfo r,
  /proc/*/mounts r,
  /proc/*/stat r,
  /proc/*/status r,
  /proc/*/task/ r,
  /proc/*/task/** r,
  /proc/cpuinfo r,
  /proc/filesystems r,
  /proc/meminfo r,
  /proc/sys/kernel/pid_max r,
  /proc/tty/drivers r,
  /proc/uptime r,

  /run/resolvconf/resolv.conf r,
  /run/shm/ r,
  /run/shm/pulse-* rw,
  /run/user/*/dconf/user rw,
  /run/user/*/pulse/ rw,
  /run/user/*/pulse/** rw,

  /sys/devices/system/cpu/online r,
  /sys/devices/system/cpu/present r,

  /tmp/ r,
  /tmp/* rw,
  /tmp/orbit-andras/ rw,
  /tmp/orbit-andras/* rw,
  /tmp/plugtmp/ rw,
  /tmp/plugtmp/** rw,
  /var/tmp/ r,

  /usr/bin/pulseaudio rix,
  /usr/bin/update-mime-database rix,
  /usr/lib/firefox/firefox rix,
  /usr/lib{,32,64}/ r,
  /usr/lib{,32,64}/** mr,
  /usr/local/share/ r,
  /usr/local/share/** r,
  /usr/share/ r,
  /usr/share/** r,

  /var/cache/fontconfig/ r,
  /var/cache/fontconfig/** r,


  /home/*/Downloads/ r,
  /home/*/Downloads/** rw,

  /home/andras/Desktop/ r,
  /home/andras/Desktop/** rw,

}
