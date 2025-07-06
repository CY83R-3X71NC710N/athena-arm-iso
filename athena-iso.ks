# athena-iso.ks
# Athena OS ARM64 (aarch64) Kickstart Configuration

lang en_US.UTF-8
keyboard us
timezone Europe/Rome
selinux --enforcing
firewall --enabled --service=mdns
xconfig --startxonboot
zerombr
clearpart --all
# ARM64/UEFI boot configuration
part /boot/efi --size 512 --fstype efi
part / --size 5120 --fstype ext4
bootloader --location=mbr --append="quiet loglevel=3 audit=0 nvme_load=yes zswap.enabled=0 fbcon=nodefer tmpfs.size=4096m nowatchdog"
services --enabled=NetworkManager,qemu-guest-agent --disabled=sshd
network --bootproto=dhcp --device=link --activate
rootpw --lock --iscrypted locked
shutdown

# Repositories used by Kickstart installation. They don't persist in the Live Environment
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
#repo --name=updates-testing --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-testing-f$releasever&arch=$basearch
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=athenaos --baseurl=https://copr-be.cloud.fedoraproject.org/results/@athenaos/athenaos/fedora-$releasever-$basearch/
# repo --name=nix --baseurl=https://copr-be.cloud.fedoraproject.org/results/petersen/nix/fedora-$releasever-$basearch/
# Note that if one of the repo URLs are wrong, the job process will stuck on "anaconda" command

# spin was failing to compose due to lack of space, so bumping the size.
#part / --size 10240

user --name=liveuser --groups=wheel --password='athena' --plaintext

%packages
#######################################################
###                  BASIC PACKAGES                 ###
#######################################################

kernel
kernel-modules
kernel-modules-extra
kernel-headers

# The point of a live image is to install
# Tools provided by these anaconda packages are used to implement ISO check and other useful packages for ISO Live environment
@anaconda-tools
anaconda-install-env-deps

# Anaconda has a weak dep on this and we don't want it on livecds, see
# https://fedoraproject.org/wiki/Changes/RemoveDeviceMapperMultipathFromWorkstationLiveCD
-fcoe-utils
-device-mapper-multipath
-sdubby

# Without this, initramfs generation during live image creation fails: #1242586
dracut-live

# anaconda needs the locales available to run for different locales
glibc-all-langpacks

# provide the livesys scripts
livesys-scripts

alsa-sof-firmware
cracklib-dicts # passwd policy checks
dhcpcd
dialog
grub2-efi-aa64
grub2-efi-aa64-modules
grub2-tools
shim-aa64
iproute
iputils
linux-firmware
lvm2
mesa-dri-drivers
mesa-vulkan-drivers
mtools
nano
net-tools
NetworkManager
network-manager-applet
nfs-utils
nss-mdns
ntpsec
os-prober
pavucontrol
pipewire
pipewire-pulseaudio
pv
rsync
squashfs-tools
sudo
terminus-fonts-console
testdisk
usbutils
vim
wireplumber
wpa_supplicant
xorg-x11-server-Xorg
xorg-x11-xinit

#######################################################
###                  WiFi Firmware                  ###
###          (Most should work on ARM64)            ###
#######################################################

NetworkManager-wifi
atheros-firmware
b43-fwcutter
b43-openfwwf
brcmfmac-firmware
iwlegacy-firmware
iwlwifi-dvm-firmware
iwlwifi-mvm-firmware
libertas-firmware
mt7xxx-firmware
nxpwireless-firmware
realtek-firmware
tiwilink-firmware
atmel-firmware
zd1211-firmware

#######################################################
###                   VPN Plugins                   ###
#######################################################
NetworkManager-sstp
NetworkManager-l2tp
NetworkManager-openconnect
NetworkManager-openvpn
NetworkManager-pptp
NetworkManager-strongswan
NetworkManager-vpnc

#######################################################
###                      FONTS                      ###
#######################################################
google-noto-color-emoji-fonts
jetbrains-mono-fonts-all

#######################################################
###                    UTILITIES                    ###
#######################################################

bat
espeak-ng
fastfetch
git
gparted
lsd
netcat
orca
polkit
ufw
wget2-wget
which
xclip
zoxide

#######################################################
###                ATHENA REPOSITORY                ###
#######################################################

aegis
aegis-tui
athena-bash
athena-config
athena-graphite-design
athena-kitty-config
#athena-powershell-config
athena-tweak-tool
athena-tmux-config
athena-vscodium-themes
athena-welcome
athena-xfce-refined
athenaos-release
#fedora-release
#athenaos-release-identity-basic
devotio
firefox-blackice

#######################################################
###                 LIVE ENVIRONMENT                ###
#######################################################
#nix
pacman
qemu-guest-agent
spice-vdagent

%end

%post
# VARIABLES
USERNAME="liveuser"

# Enable livesys services
systemctl enable livesys.service
systemctl enable livesys-late.service
#systemctl enable nix-daemon.service

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
echo "Packages within this LiveCD"
rpm -qa --qf '%{size}\t%{name}-%{version}-%{release}.%{arch}\n' |sort -rn
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
systemctl disable network

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# etc/default/grub

cat > /etc/default/grub <<'EOF'
# GRUB boot loader configuration

GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 audit=0 nvme_load=yes zswap.enabled=0 fbcon=nodefer tmpfs.size=4096m nowatchdog"
GRUB_CMDLINE_LINUX=""

# Preload both GPT and EFI modules for ARM64/UEFI systems
GRUB_PRELOAD_MODULES="part_gpt efi_gop efi_uga"

# Uncomment to enable booting from LUKS encrypted devices
#GRUB_ENABLE_CRYPTODISK=y

# Set to 'countdown' or 'hidden' to change timeout behavior,
# press ESC key to display menu.
#GRUB_TIMEOUT_STYLE=menu

# Uncomment to use basic console
GRUB_TERMINAL_INPUT=console

# Uncomment to disable graphical terminal
#GRUB_TERMINAL_OUTPUT=console

# The resolution used on graphical terminal
# note that you can use only modes which your graphic card supports via VBE
# you can see them in real GRUB with the command `vbeinfo'
GRUB_GFXMODE=1280x720

# Uncomment to allow the kernel use the same resolution used by grub
GRUB_GFXPAYLOAD_LINUX=keep

# Uncomment if you want GRUB to pass to the Linux kernel the old parameter
# format "root=/dev/xxx" instead of "root=/dev/disk/by-uuid/xxx"
#GRUB_DISABLE_LINUX_UUID=true

# Uncomment to disable generation of recovery mode menu entries
GRUB_DISABLE_RECOVERY=true

# Uncomment and set to the desired menu colors.  Used by normal and wallpaper
# modes only.  Entries specified as foreground/background.
#GRUB_COLOR_NORMAL="light-blue/black"
#GRUB_COLOR_HIGHLIGHT="light-cyan/blue"

# Uncomment one of them for the gfx desired, a image background or a gfxtheme
#GRUB_BACKGROUND="/usr/share/backgrounds/default/grub.png"
#GRUB_THEME="/usr/share/grub/themes/starfield/theme.txt"

# Uncomment to get a beep at GRUB start
#GRUB_INIT_TUNE="480 440 1"

# Uncomment to make GRUB remember the last selection. This requires
# setting 'GRUB_DEFAULT=saved' above. Change 0 into saved.
# Do not forget to 'update-grub' in a terminal to apply the new settings
#GRUB_SAVEDEFAULT="true"

# Uncomment to make grub stop using submenus
#GRUB_DISABLE_SUBMENU=y

# Check for other operating systems
GRUB_DISABLE_OS_PROBER=false
EOF

# Creating profile files directly on user home (and not on skel) because the account is created at the first stage of kickstart
# .bash_profile
cat > /home/${USERNAME}/.bash_profile <<'EOF'
#
# ~/.bash_profile
#
# xinit <session> will look for ~/.xinitrc content
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  # By autologin with no display manager, XDG_SESSION_TYPE will be set as tty
  # If the system does not recognize x11, some things like spice-vdagent for qemu
  # or the application of XFCE backgrounds by CLI could not work
  export XDG_SESSION_TYPE=x11
  startx ~/.xinitrc xfce4 &>/dev/null
fi
EOF

# .xinitrc
cat > /home/${USERNAME}/.xinitrc <<'EOF'
# Here Xfce is kept as default
session=${1:-xfce}

case $session in
    i3|i3wm           ) exec i3;;
    kde               ) exec startplasma-x11;;
    xfce|xfce4        ) exec startxfce4;;
    # No known session, try to run it as command
    *                 ) exec $1;;
esac
EOF

# autologin.conf
# Usage of EOF with no single quotes to expand USERNAME variable
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${USERNAME} --noclear %I \$TERM
EOF

# .bashrc
# The usage of 'EOF' with single-quotes prevent variable expansions
cat > /home/${USERNAME}/.bashrc <<'EOF'
# ~/.bashrc

# Append "$1" to $PATH when not already in.
append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}
append_path "$HOME/bin"
append_path "$HOME/.local/bin"

### EXPORT ### Should be before the change of the shell
export EDITOR=/usr/bin/nvim
export VISUAL='nano'
export HISTCONTROL=ignoreboth:erasedups:ignorespace
HISTSIZE=100000
HISTFILESIZE=2000000
shopt -s histappend
export PAGER='most'

export TERM=xterm-256color
export SHELL=$(which bash)

export PAYLOADS="/usr/share/payloads"
export SECLISTS="$PAYLOADS/seclists"
export PAYLOADSALLTHETHINGS="$PAYLOADS/payloadsallthethings"
export FUZZDB="$PAYLOADS/fuzzdb"
export AUTOWORDLISTS="$PAYLOADS/autowordlists"
export SECURITYWORDLIST="$PAYLOADS/security-wordlist"

export MIMIKATZ="/usr/share/windows/mimikatz/"
export POWERSPLOIT="/usr/share/windows/powersploit/"

export ROCKYOU="$SECLISTS/Passwords/Leaked-Databases/rockyou.txt"
export DIRSMALL="$SECLISTS/Discovery/Web-Content/directory-list-2.3-small.txt"
export DIRMEDIUM="$SECLISTS/Discovery/Web-Content/directory-list-2.3-medium.txt"
export DIRBIG="$SECLISTS/Discovery/Web-Content/directory-list-2.3-big.txt"
export WEBAPI_COMMON="$SECLISTS/Discovery/Web-Content/api/api-endpoints.txt"
export WEBAPI_MAZEN="$SECLISTS/Discovery/Web-Content/common-api-endpoints-mazen160.txt"
export WEBCOMMON="$SECLISTS/Discovery/Web-Content/common.txt"
export WEBPARAM="$SECLISTS/Discovery/Web-Content/burp-parameter-names.txt"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# --- One-time setup ---
if [[ $1 != no-repeat-flag && -z $NO_REPETITION ]]; then
  export NO_REPETITION=1
  fastfetch
fi

# Optional: Source Blesh if installed
[[ $1 != no-repeat-flag && -f /usr/share/blesh/ble.sh ]] && source /usr/share/blesh/ble.sh

# --- Bash completion ---
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# --- Aliases ---
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# --- Shell behavior ---
shopt -s autocd
shopt -s cdspell
shopt -s cmdhist
shopt -s dotglob
shopt -s histappend
shopt -s expand_aliases

# --- ex (extractor helper) ---
ex () {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.bz2)       bunzip2 "$1"   ;;
      *.rar)       unrar x "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.tar)       tar xf "$1"    ;;
      *.tbz2)      tar xjf "$1"   ;;
      *.tgz)       tar xzf "$1"   ;;
      *.zip)       unzip "$1"     ;;
      *.Z)         uncompress "$1";;
      *.7z)        7z x "$1"      ;;
      *.deb)       ar x "$1"      ;;
      *.tar.xz)    tar xf "$1"    ;;
      *.tar.zst)   tar xf "$1"    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# --- Git helpers ---
vimod () {
  vim -p $(git status -suall | awk '{print $2}')
}

virev () {
  local commit=${1:-HEAD}
  local rootdir=$(git rev-parse --show-toplevel)
  local sourceFiles=$(git show --name-only --pretty="format:" "$commit" | grep -v '^$')
  local toOpen=""
  for file in $sourceFiles; do
    local fullpath="$rootdir/$file"
    [ -e "$fullpath" ] && toOpen="$toOpen $fullpath"
  done
  if [ -z "$toOpen" ]; then
    echo "No files were modified in $commit"
    return 1
  fi
  vim -p $toOpen
}

gitPrompt() {
  command -v __git_ps1 > /dev/null && __git_ps1 " (%s)"
}

# --- cd up helper ---
cu () {
  local count=$1
  [[ -z "$count" ]] && count=1
  local upath=""
  for i in $(seq 1 $count); do
    upath+="../"
  done
  cd "$upath"
}

# --- Memory cleaning helper ---
buffer_clean(){
  free -h && sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches' && free -h
}

# --- Fish-style dynamic prompt ---
set_bash_prompt() {
  local last_status=$?
  local tty_device=$(tty)
  local ip=$(ip -4 addr | grep -v '127.0.0.1' | grep -v 'secondary' \
    | grep -oP '(?<=inet\s)\d+(\.\d+){3}' \
    | sed -z 's/\n/|/g;s/|\$/\n/' \
    | rev | cut -c 2- | rev)

  local user="\u"
  local host="\h"
  local cwd="\w"
  local branch=""
  local hq_prefix=""
  local flame=""
  local robot=""

  if command -v git &>/dev/null; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  fi

  if [[ "$tty_device" == /dev/tty* ]]; then
    hq_prefix="HQ─"
    flame=""
    robot="[>]"
  else
    hq_prefix="HQ🚀🌐"
    flame="🔥"
    robot="[👾]"
  fi

  if [[ $last_status -eq 0 ]]; then
    user_host="\[\e[1;34m\]($user@$host)\[\e[0m\]"
  else
    user_host="\[\e[1;31m\]($user@$host)\[\e[0m\]"
  fi

  local line1="\[\e[1;32m\]╭─[$hq_prefix\[\e[1;31m\]$ip\[\e[1;32m\]$flame]─$user_host"
  if [[ -n "$branch" ]]; then
    line1+="\[\e[1;33m\][ $branch]\[\e[0m\]"
  fi

  local line2="\[\e[1;32m\]╰─>$robot\[\e[1;36m\]$cwd \$\[\e[0m\]"

  PS1="${line1}\n${line2} "
}

PROMPT_COMMAND='set_bash_prompt'

EOF


# athenaos.repo
cat > /etc/yum.repos.d/athenaos.repo <<EOF
[athenaos]
name=Athena OS \$releasever - \$basearch
baseurl=https://download.copr.fedorainfracloud.org/results/@athenaos/athenaos/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=0
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

# microsoft.repo
cat > /etc/yum.repos.d/microsoft.repo <<EOF
[microsoft-fedora]
name=Microsoft Fedora \$releasever
baseurl=https://packages.microsoft.com/fedora/\$releasever/prod/
gpgcheck=0
repo_gpgcheck=0
enabled=1
gpgkey=https://packages.microsoft.com/fedora/\$releasever/prod/repodata/repomd.xml.key
EOF


echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/g_wheel
chmod 0440 /etc/sudoers.d/g_wheel


# Disable graphical target because, in ISO Live, Display Manager is not used.
# Otherwise Fedora Live might default to graphical.target, expecting gdm, and it could slow boot for a few seconds.
#systemctl set-default multi-user.target

%end