#!/bin/bash
# =====================================================================
#  Baut das ISO-Image deiner Distribution.
#
#  Voraussetzung: ein Debian-System (oder ./build-in-docker.sh benutzen)
#  Aufruf:        sudo ./build.sh            (normaler Build)
#                 sudo ./build.sh --clean    (alles inkl. Paket-Cache neu)
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31mFehler: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Bitte mit Root-Rechten starten: sudo ./build.sh"

# shellcheck source=distro.conf
. ./distro.conf

# --- Einstellungen prüfen -----------------------------------------------
[[ "${DISTRO_ID}" =~ ^[a-z0-9]+$ ]] || die "DISTRO_ID darf nur Kleinbuchstaben und Ziffern enthalten."
VOLUME="${DISTRO_NAME} ${DISTRO_VERSION}"
[ "${#VOLUME}" -le 32 ] || die "\"${VOLUME}\" ist zu lang für das ISO-Label (max. 32 Zeichen)."

# --- Werkzeuge ------------------------------------------------------------
NEEDED="live-build apt-utils librsvg2-bin fonts-cantarell fonts-dejavu-core curl ca-certificates gnupg"
MISSING=""
for p in ${NEEDED}; do
	dpkg-query -W -f='${Status}' "${p}" 2>/dev/null | grep -q "install ok installed" || MISSING="${MISSING} ${p}"
done
if [ -n "${MISSING}" ]; then
	say "Installiere Build-Werkzeuge:${MISSING}"
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${MISSING}
fi

# --- Aufräumen ----------------------------------------------------------
if [ "${1:-}" = "--clean" ]; then
	say "Komplett neu bauen (inkl. Paket-Cache)"
	lb clean --purge
else
	lb clean
fi

# --- Branding rendern und ins Image legen -------------------------------
STAGE="config/includes.chroot_after_packages/root/distro-build"
say "Rendere Branding für ${DISTRO_NAME}"
rm -rf "${STAGE}"
mkdir -p "${STAGE}"
cp distro.conf "${STAGE}/distro.conf"
cp -r nvidia "${STAGE}/nvidia"
branding/render.sh "${STAGE}/branding"

# --- live-build konfigurieren -------------------------------------------
say "Konfiguriere live-build (Debian ${DEBIAN_SUITE}, ${ARCH})"
lb config

# --- Debian "contrib" als Zusatzquelle --------------------------------------
# Nicht in --archive-areas (siehe auto/config), aber für einzelne Pakete wie
# nvidia-settings (Treiber 550) nötig. So bleibt die automatische
# Firmware-Auswahl von live-build frei von Download-"Installern".
mkdir -p config/archives
rm -f config/archives/debian-contrib.*
cat > config/archives/debian-contrib.list.chroot <<LIST
deb ${BUILD_MIRROR} @DISTRIBUTION@ contrib
deb ${BUILD_MIRROR} @DISTRIBUTION@-updates contrib
deb ${BUILD_MIRROR_SECURITY} @DISTRIBUTION@-security contrib
LIST
cat > config/archives/debian-contrib.list.binary <<LIST
deb ${FINAL_MIRROR} @DISTRIBUTION@ contrib
deb ${FINAL_MIRROR} @DISTRIBUTION@-updates contrib
deb ${FINAL_MIRROR_SECURITY} @DISTRIBUTION@-security contrib
LIST

# --- NVIDIA-Paketquelle ----------------------------------------------------
rm -f config/archives/nvidia.* config/package-lists/nvidia.list.chroot
if [ "${NVIDIA_SUPPORT}" = "yes" ]; then
	say "Richte NVIDIA-Paketquelle ein (Treiberreihe ${NVIDIA_BRANCH})"
	mkdir -p config/archives
	TMP="$(mktemp -d)"
	# Schlüssel aus NVIDIAs offiziellem Paket "cuda-keyring" (per HTTPS geladen)
	KEYRING_DEB="$(curl -fsSL "${NVIDIA_REPO}" | grep -oE 'cuda-keyring_[0-9.]+-[0-9]+_all\.deb' | sort -V | tail -n1)"
	[ -n "${KEYRING_DEB}" ] || die "cuda-keyring nicht gefunden unter ${NVIDIA_REPO}"
	curl -fsSL "${NVIDIA_REPO}${KEYRING_DEB}" -o "${TMP}/keyring.deb"
	dpkg-deb -x "${TMP}/keyring.deb" "${TMP}/keyring"
	KEYRING="$(find "${TMP}/keyring" -name '*.gpg' -path '*keyrings*' | head -n1)"
	gpg --batch --no-default-keyring --keyring "${KEYRING}" --export --armor > config/archives/nvidia.key.chroot
	gpg --batch --no-default-keyring --keyring "${KEYRING}" --list-keys --with-fingerprint 2>/dev/null | sed 's/^/    /'
	rm -rf "${TMP}"
	cp config/archives/nvidia.key.chroot config/archives/nvidia.key.binary

	# Beim Bauen per http (wie die Debian-Spiegel, Signaturen prüft apt),
	# im fertigen System per https.
	echo "deb ${NVIDIA_REPO/https:/http:} /" > config/archives/nvidia.list.chroot
	echo "deb ${NVIDIA_REPO_FINAL:-${NVIDIA_REPO}} /" > config/archives/nvidia.list.binary

	# NVIDIA-Pakete aus NVIDIAs Quelle bevorzugen und auf die Treiberreihe festnageln
	cat > config/archives/nvidia.pref.chroot <<PREF
Package: *
Pin: origin developer.download.nvidia.com
Pin-Priority: 600

Package: /nvidia/ /^libcuda1/ /^libnvcuvid1/ /^libnvoptix1/ /^libxnvctrl0/
Pin: version ${NVIDIA_BRANCH}.*
Pin-Priority: 1001
PREF
	cp config/archives/nvidia.pref.chroot config/archives/nvidia.pref.binary
	cp nvidia/packages.list config/package-lists/nvidia.list.chroot
fi

# --- Bootmenü (GRUB für UEFI, ISOLINUX für BIOS) ----------------------------
# live-build nimmt Vorlagen aus config/bootloaders/, falls vorhanden. Wir
# kopieren Debians Standardvorlagen und passen Bild, Einträge und Texte an.
say "Passe Bootmenü an"
BL=config/bootloaders
rm -rf "${BL}"
mkdir -p "${BL}"
cp -a /usr/share/live/build/bootloaders/. "${BL}/"
rm -f "${BL}/splash.svg"
cp "${STAGE}/branding/splash.png"    "${BL}/grub-pc/splash.png"
cp "${STAGE}/branding/splash640.png" "${BL}/isolinux/splash.png"

# Notfall-Eintrag: NVIDIA-Treiber sperren, freien Treiber nouveau verwenden
GPU_NOUVEAU="modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm ${DISTRO_ID}.gpu=nouveau"

# GRUB: eigene Einträge statt der automatisch erzeugten "Live system (amd64)"
cat > "${BL}/grub-pc/live-entries.cfg" <<GRUB
menuentry "${DISTRO_NAME} Live" --hotkey=l {
	linux	@KERNEL_LIVE@ @APPEND_LIVE@
	initrd	@INITRD_LIVE@
}
menuentry "${DISTRO_NAME} Live – Open-Source-Grafiktreiber (nouveau)" --hotkey=n {
	linux	@KERNEL_LIVE@ @APPEND_LIVE@ ${GPU_NOUVEAU}
	initrd	@INITRD_LIVE@
}
menuentry "${DISTRO_NAME} Live – abgesicherter Modus" --hotkey=s {
	linux	@KERNEL_LIVE@ @LB_BOOTAPPEND_LIVE_FAILSAFE@
	initrd	@INITRD_LIVE@
}
GRUB
awk -v f="${BL}/grub-pc/live-entries.cfg" '
	/^@LINUX_LIVE@$/ { while ((getline line < f) > 0) print line; next }
	{ print }' "${BL}/grub-pc/grub.cfg" > "${BL}/grub-pc/grub.cfg.new"
mv "${BL}/grub-pc/grub.cfg.new" "${BL}/grub-pc/grub.cfg"
rm -f "${BL}/grub-pc/live-entries.cfg"
sed -i \
	-e "s|submenu 'Utilities...'|submenu 'Werkzeuge ...'|" \
	-e 's|"UEFI Firmware Settings"|"UEFI-Firmware-Einstellungen"|' \
	-e 's|"Verify integrity of the boot medium"|"Startmedium auf Fehler prüfen"|' \
	"${BL}/grub-pc/grub.cfg"
sed -i 's|^set default=0|set default=0\nset timeout=10|' "${BL}/grub-pc/config.cfg"
sed -i -e 's|^title-text:.*|title-text: ""|' \
	-e 's|@TIMEOUT_NOTIFICATION_LONG@|Automatischer Start in %d Sekunden|' \
	-e 's|@KEYMAP_SHORT@|Enter: starten · E: Startoptionen bearbeiten · C: Kommandozeile|' \
	"${BL}/grub-pc/live-theme/theme.txt"

# ISOLINUX (BIOS): gleiche Einträge; nur ASCII, da ISOLINUX kein UTF-8 kann
cat > "${BL}/syslinux_common/live.cfg.in" <<SYSLINUX
label live-@FLAVOUR@
	menu label ^${DISTRO_NAME} Live
	menu default
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@

label live-@FLAVOUR@-nouveau
	menu label ${DISTRO_NAME} Live - ^Open-Source-Grafiktreiber (nouveau)
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE@ ${GPU_NOUVEAU}

label live-@FLAVOUR@-failsafe
	menu label ${DISTRO_NAME} Live - ^abgesicherter Modus
	linux @LINUX@
	initrd @INITRD@
	append @APPEND_LIVE_FAILSAFE@
SYSLINUX
sed -i \
	-e '/^menu title Boot menu/d' \
	-e 's|menu label ^Utilities|menu label ^Werkzeuge|' \
	-e 's|menu title Utilities|menu title Werkzeuge|' \
	-e 's|menu label ^Back..|menu label ^Zurueck|' \
	"${BL}/syslinux_common/menu.cfg"
SEL="#ff${COLOR_PRIMARY#\#}"
sed -i \
	-e "s|#76a1d0ff|${SEL}|g" \
	-e 's|^menu vshift 12|menu vshift 14|' \
	-e 's|^menu tabmsg .*|menu tabmsg ENTER: starten    TAB: Startoptionen bearbeiten|' \
	-e '$a menu autoboot Automatischer Start in # Sekunden ...' \
	"${BL}/syslinux_common/stdmenu.cfg"
sed -i 's|^timeout 0|timeout 100|' "${BL}/isolinux/isolinux.cfg"

# --- Bauen -----------------------------------------------------------------
say "Baue ${DISTRO_NAME} ${DISTRO_VERSION} – das dauert eine Weile (Log: build.log)"
START=$(date +%s)
lb build 2>&1 | tee build.log

ISO="${DISTRO_ID}-${DISTRO_VERSION}-${ARCH}.hybrid.iso"
[ -f "${ISO}" ] || die "Kein ISO entstanden – siehe build.log"
sha256sum "${ISO}" > "${ISO}.sha256"

MIN=$(( ($(date +%s) - START) / 60 ))
say "Fertig nach ${MIN} Minuten: ${ISO} ($(du -h "${ISO}" | cut -f1))"
echo "    Testen:          ./test-vm.sh ${ISO}"
echo "    Auf USB-Stick:   sudo dd if=${ISO} of=/dev/sdX bs=4M status=progress oflag=sync"
