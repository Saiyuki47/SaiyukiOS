#!/bin/bash
# Startet das ISO in einer virtuellen Maschine (QEMU).
#   ./test-vm.sh                 neuestes ISO, BIOS-Modus
#   ./test-vm.sh --uefi          im UEFI-Modus starten
#   ./test-vm.sh --disk          mit virtueller 25-GB-Festplatte (zum Testen des Installers)
#   ./test-vm.sh --boot-disk     die installierte virtuelle Festplatte starten (ohne ISO)
set -euo pipefail
cd "$(dirname "$0")"

ISO="" UEFI=0 DISK=0 BOOTDISK=0
for a in "$@"; do
	case "$a" in
		--uefi) UEFI=1 ;;
		--disk) DISK=1 ;;
		--boot-disk) DISK=1; BOOTDISK=1 ;;
		*.iso) ISO="$a" ;;
		*) echo "Unbekannte Option: $a" >&2; exit 1 ;;
	esac
done
[ -n "${ISO}" ] || ISO="$(ls -t ./*.iso 2>/dev/null | head -n1 || true)"
[ "${BOOTDISK}" = 1 ] || [ -f "${ISO}" ] || { echo "Kein ISO gefunden. Erst ./build.sh ausführen." >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo "Bitte installieren: sudo apt install qemu-system-x86 ovmf" >&2; exit 1; }

ARGS=(-m 4096 -smp 2 -vga virtio -nic user,model=virtio-net-pci -device qemu-xhci -device usb-tablet)
if [ -w /dev/kvm ]; then
	ARGS+=(-enable-kvm -cpu host)
else
	echo "Hinweis: kein KVM – die VM läuft deutlich langsamer."
	# Ohne KVM rendert Plasma per Software (llvmpipe). Dessen AVX-Code läuft
	# in QEMUs CPU-Emulation nicht stabil, daher ein CPU-Modell ohne AVX.
	ARGS+=(-accel tcg,thread=multi -cpu Westmere)
fi

if [ "${UEFI}" = 1 ]; then
	CODE=/usr/share/OVMF/OVMF_CODE_4M.fd VARS=/usr/share/OVMF/OVMF_VARS_4M.fd
	[ -f "${CODE}" ] || { echo "OVMF fehlt: sudo apt install ovmf" >&2; exit 1; }
	[ -f vm-uefi-vars.fd ] || cp "${VARS}" vm-uefi-vars.fd
	ARGS+=(-drive "if=pflash,format=raw,readonly=on,file=${CODE}" -drive "if=pflash,format=raw,file=vm-uefi-vars.fd")
fi
if [ "${DISK}" = 1 ]; then
	[ -f vm-disk.qcow2 ] || qemu-img create -f qcow2 vm-disk.qcow2 25G
	ARGS+=(-drive file=vm-disk.qcow2,if=virtio)
fi
[ "${BOOTDISK}" = 1 ] || ARGS+=(-cdrom "${ISO}" -boot d)

exec qemu-system-x86_64 "${ARGS[@]}"
