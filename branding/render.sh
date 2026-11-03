#!/bin/sh
# Rendert die SVG-Vorlagen (branding/*.svg.in) mit den Werten aus distro.conf zu PNG.
# Aufruf: branding/render.sh <Ausgabeverzeichnis>
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:?Ausgabeverzeichnis fehlt}"
. "${HERE}/../distro.conf"

command -v rsvg-convert >/dev/null || { echo "rsvg-convert fehlt (Paket librsvg2-bin)" >&2; exit 1; }
mkdir -p "${OUT}"

# Wert für sed escapen (Trennzeichen |, & und \)
esc() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }

fill() {
	sed -e "s|@NAME@|$(esc "${DISTRO_NAME}")|g" \
	    -e "s|@VERSION@|$(esc "${DISTRO_VERSION}")|g" \
	    -e "s|@TAGLINE@|$(esc "${DISTRO_TAGLINE}")|g" \
	    -e "s|@PRIMARY@|$(esc "${COLOR_PRIMARY}")|g" \
	    -e "s|@ACCENT@|$(esc "${COLOR_ACCENT}")|g" \
	    -e "s|@DARK@|$(esc "${COLOR_DARK}")|g" \
	    "$1"
}

# 1) Logo zuerst (wird in andere Grafiken eingebettet)
fill "${HERE}/logo.svg.in" > "${OUT}/logo.svg"
for size in 16 22 24 32 48 64 128 256 512; do
	rsvg-convert -w "${size}" -h "${size}" "${OUT}/logo.svg" -o "${OUT}/logo-${size}.png"
done
LOGO_PNG="data:image/png;base64,$(base64 -w0 "${OUT}/logo-256.png")"

# 2) Alle übrigen Vorlagen
for tpl in "${HERE}"/*.svg.in; do
	name="$(basename "${tpl}" .in)"
	[ "${name}" = "logo.svg" ] && continue
	fill "${tpl}" | sed -e "s|@LOGO_PNG@|${LOGO_PNG}|g" > "${OUT}/${name}"
done

for res in 1920x1080 2560x1440 3840x2160; do
	rsvg-convert -w "${res%x*}" -h "${res#*x}" "${OUT}/wallpaper.svg" -o "${OUT}/wallpaper-${res}.png"
done
cp "${OUT}/wallpaper-1920x1080.png" "${OUT}/wallpaper.png"
rsvg-convert -w 400 -h 225 "${OUT}/wallpaper.svg" -o "${OUT}/wallpaper-preview.png"
rsvg-convert -w 800  -h 600  "${OUT}/splash.svg"    -o "${OUT}/splash.png"
rsvg-convert -w 640  -h 480  "${OUT}/splash.svg"    -o "${OUT}/splash640.png"

# 3) ASCII-Logo (für fastfetch und den Text-Login)
cp "${HERE}/ascii-logo.txt" "${OUT}/ascii-logo.txt"

echo "Branding gerendert nach ${OUT}"
