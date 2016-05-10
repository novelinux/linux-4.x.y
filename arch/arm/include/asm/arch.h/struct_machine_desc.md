struct machine_desc
========================================

path: arch/arm/include/asm/mach/arch.h
```
struct machine_desc {
    unsigned int        nr;        /* architecture number    */
    const char          *name;        /* architecture name    */
    unsigned long       atag_offset;    /* tagged list (relative) */
    const char *const   *dt_compat;    /* array of device tree
                                        * 'compatible' strings    */

    unsigned int        nr_irqs;    /* number of IRQs */

#ifdef CONFIG_ZONE_DMA
    phys_addr_t        dma_zone_size;    /* size of DMA-able area */
#endif

    unsigned int        video_start;    /* start of video RAM    */
    unsigned int        video_end;    /* end of video RAM    */

    unsigned char        reserve_lp0 :1;    /* never has lp0    */
    unsigned char        reserve_lp1 :1;    /* never has lp1    */
    unsigned char        reserve_lp2 :1;    /* never has lp2    */

    enum reboot_mode    reboot_mode;    /* default restart mode    */

    unsigned        l2c_aux_val;    /* L2 cache aux value    */
    unsigned        l2c_aux_mask;    /* L2 cache aux mask    */
    void            (*l2c_write_sec)(unsigned long, unsigned);
    struct smp_operations    *smp;        /* SMP operations    */
    bool            (*smp_init)(void);
    void            (*fixup)(struct tag *, char **);
    void            (*dt_fixup)(void);
    void            (*init_meminfo)(void);
    void            (*reserve)(void);/* reserve mem blocks    */
    void            (*map_io)(void);/* IO mapping function    */
    void            (*init_early)(void);
    void            (*init_irq)(void);
    void            (*init_time)(void);
    void            (*init_machine)(void);
    void            (*init_late)(void);
#ifdef CONFIG_MULTI_IRQ_HANDLER
    void            (*handle_irq)(struct pt_regs *);
#endif
    void            (*restart)(enum reboot_mode, const char *);
};
```