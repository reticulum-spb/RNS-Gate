# Compiled into CONFIG_BOOTCOMMAND by generate-boot-config.py.
# SWUpdate uses the gate_* U-Boot state managed by this boot command.
if test "${gate_active}" != "A" && test "${gate_active}" != "B"; then
    setenv gate_active A;
    setenv gate_pending;
    setenv gate_tries 0;
    saveenv;
fi;
setenv gate_bootslot ${gate_active};
if test "${gate_pending}" = "A" || test "${gate_pending}" = "B"; then
    if test "${gate_tries}" = "1" || test "${gate_tries}" = "2" || test "${gate_tries}" = "3"; then
        setexpr gate_tries ${gate_tries} - 1;
        saveenv;
        setenv gate_bootslot ${gate_pending};
    else
        setenv gate_pending;
        setenv gate_tries 0;
        saveenv;
    fi;
fi;
if test "${gate_bootslot}" = "B"; then
    setenv gate_part 2;
else
    setenv gate_part 1;
fi;
setenv bootargs root=/dev/mmcblk0p${gate_part} rootwait console=ttyS0,115200 rootfstype=ext4 panic=10 gate.slot=${gate_bootslot};
if ext4load mmc 0:${gate_part} ${kernel_addr_r} /boot/zImage; then
    if ext4load mmc 0:${gate_part} ${fdt_addr_r} /boot/gate.dtb; then
        bootz ${kernel_addr_r} - ${fdt_addr_r};
    fi;
fi;
sleep 2;
reset;
