# Compiled into CONFIG_BOOTCOMMAND by generate-boot-config.py.
# RAUC-managed A/B selection using the BOOT_ORDER/BOOT_<slot>_LEFT
# environment contract (bootnames A and B, see rauc-system.conf).
test -n "${BOOT_ORDER}" || setenv BOOT_ORDER "A B";
test -n "${BOOT_A_LEFT}" || setenv BOOT_A_LEFT 3;
test -n "${BOOT_B_LEFT}" || setenv BOOT_B_LEFT 3;
setenv bootargs;
for BOOT_SLOT in ${BOOT_ORDER};
do
if test "x${bootargs}" = "x"; then
if test "x${BOOT_SLOT}" = "xA"; then
if test ${BOOT_A_LEFT} -gt 0; then
setexpr BOOT_A_LEFT ${BOOT_A_LEFT} - 1;
setenv gate_part 1;
setenv bootargs root=/dev/mmcblk0p1 rootwait console=ttyS0,115200 rootfstype=ext4 panic=10 memtest=4 rauc.slot=A;
echo "RAUC: booting slot A, ${BOOT_A_LEFT} attempts left";
fi;
fi;
if test "x${BOOT_SLOT}" = "xB"; then
if test ${BOOT_B_LEFT} -gt 0; then
setexpr BOOT_B_LEFT ${BOOT_B_LEFT} - 1;
setenv gate_part 2;
setenv bootargs root=/dev/mmcblk0p2 rootwait console=ttyS0,115200 rootfstype=ext4 panic=10 memtest=4 rauc.slot=B;
echo "RAUC: booting slot B, ${BOOT_B_LEFT} attempts left";
fi;
fi;
fi;
done;
if test "x${bootargs}" = "x"; then
echo "RAUC: no bootable slot, resetting attempts";
setenv BOOT_A_LEFT 3;
setenv BOOT_B_LEFT 3;
setenv BOOT_ORDER "A B";
saveenv;
reset;
fi;
saveenv;
if ext4load mmc 0:${gate_part} ${kernel_addr_r} /boot/zImage; then
if ext4load mmc 0:${gate_part} ${fdt_addr_r} /boot/gate.dtb; then
bootz ${kernel_addr_r} - ${fdt_addr_r};
fi;
fi;
sleep 2;
reset;
