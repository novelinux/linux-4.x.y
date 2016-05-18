GFP
========================================

mask
----------------------------------------

Linux将内存划分为内存域。内核提供了所谓的内存域修饰符(zone modifier)(在掩码的最低4个比特位定义)，
来指定从哪个内存域分配所需的页。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/mask.md

__GFP_MOVABLE不表示物理内存域，但通知内核应该在特殊的虚拟内存域ZONE_MOVABLE进行相应的分配。
很有趣的一点是，没有__GFP_NORMAL常数，而内存分配的主要负担却落到ZONE_NORMAL内存域。内核考虑
到这一点，提供了一个函数来计算与给定分配标志兼容的最高内存域。那么内存分配可以从该内存域或
更低的内存域进行。gfp_zone函数就是用mask寻找到合适内存域类型的函数:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/gfp_zone.md

flags
----------------------------------------

除了内存域修饰符之外，掩码中还可以设置一些标志。下图给出了掩码的布局，以及与各个比特位置关联的
常数。__GFP_DMA32出现了几次，因为它可能位于不同的地方。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/res/flags-mask.jpg

与内存域修饰符相反，这些额外的标志并不限制从哪个物理内存段分配内存，但确实可以改变分配器的行为。
例如，它们可以修改查找空闲内存时的积极程度。内核源代码中定义的下列标志：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/flags.md

flags的目的内核为了将已分配页进行分组，可以通过flags找到合适的migratetype:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/gfpflags_to_migratetype.md
