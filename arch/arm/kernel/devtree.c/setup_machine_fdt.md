setup_machine_fdt
========================================

setup_machine_fdt函数的功能就是根据Device Tree的信息，找到最适合的machine描述符。
具体代码如下：

early_init_dt_verify
----------------------------------------

path: arch/arm/kernel/devtree.c
```
/**
 * setup_machine_fdt - Machine setup when an dtb was passed to the kernel
 * @dt_phys: physical address of dt blob
 *
 * If a dtb was passed to the kernel in r2, then use it to choose the
 * correct machine_desc and to setup the system.
 */
const struct machine_desc * __init setup_machine_fdt(unsigned int dt_phys)
{
    const struct machine_desc *mdesc, *mdesc_best = NULL;

#ifdef CONFIG_ARCH_MULTIPLATFORM
    DT_MACHINE_START(GENERIC_DT, "Generic DT based system")
    MACHINE_END

    mdesc_best = &__mach_desc_GENERIC_DT;
#endif

    if (!dt_phys || !early_init_dt_verify(phys_to_virt(dt_phys)))
        return NULL;
```

of_flat_dt_match_machine
----------------------------------------

of_flat_dt_match_machine是在machine描述符的列表中scan，找到最合适的那个machine描述符。

```
    mdesc = of_flat_dt_match_machine(mdesc_best, arch_get_next_mach);

    if (!mdesc) {
        const char *prop;
        int size;
        unsigned long dt_root;

        early_print("\nError: unrecognized/unsupported "
                "device tree compatible list:\n[ ");

        dt_root = of_get_flat_dt_root();
        prop = of_get_flat_dt_prop(dt_root, "compatible", &size);
        while (size > 0) {
            early_print("'%s' ", prop);
            size -= strlen(prop) + 1;
            prop += strlen(prop) + 1;
        }
        early_print("]\n\n");

        dump_machine_table(); /* does not return */
    }

    /* We really don't want to do this, but sometimes firmware provides buggy data */
    if (mdesc->dt_fixup)
        mdesc->dt_fixup();
```

early_init_dt_scan_nodes
----------------------------------------

```
    early_init_dt_scan_nodes();

    /* Change machine number to match the mdesc we're using */
    __machine_arch_type = mdesc->nr;

    return mdesc;
}
```