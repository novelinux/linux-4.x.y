enum pageblock_bits
========================================

```
/* Bit indices that affect a whole block of pages */
enum pageblock_bits {
     PB_migrate,
     /* 3 bits required for migrate types */
     PB_migrate_end = PB_migrate + 3 - 1,
     PB_migrate_skip,     /* If set the block is skipped by compaction */

     /*
      * Assume the bits will always align on a word. If this assumption
      * changes then get/set pageblock needs updating.
      */
      NR_PAGEBLOCK_BITS
};
```