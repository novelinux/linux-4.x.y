size_index
========================================

path: mm/slab_common.c
```
/*
 * Conversion table for small slabs sizes / 8 to the index in the
 * kmalloc array. This is necessary for slabs < 192 since we have non power
 * of two cache sizes there. The size of larger slabs can be determined using
 * fls.
 */
static s8 size_index[24] = {
    3,    /* 8 */
    4,    /* 16 */
    5,    /* 24 */
    5,    /* 32 */
    6,    /* 40 */
    6,    /* 48 */
    6,    /* 56 */
    6,    /* 64 */
    1,    /* 72 */
    1,    /* 80 */
    1,    /* 88 */
    1,    /* 96 */
    7,    /* 104 */
    7,    /* 112 */
    7,    /* 120 */
    7,    /* 128 */
    2,    /* 136 */
    2,    /* 144 */
    2,    /* 152 */
    2,    /* 160 */
    2,    /* 168 */
    2,    /* 176 */
    2,    /* 184 */
    2     /* 192 */
};
```