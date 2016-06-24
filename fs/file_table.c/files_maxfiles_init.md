files_maxfiles_init
========================================

path: fs/file_table.c
```
/*
 * One file with associated inode and dcache is very roughly 1K. Per default
 * do not use more than 10% of our memory for files.
 */
void __init files_maxfiles_init(void)
{
    unsigned long n;
    unsigned long memreserve = (totalram_pages - nr_free_pages()) * 3/2;

    memreserve = min(memreserve, totalram_pages - 1);
    n = ((totalram_pages - memreserve) * (PAGE_SIZE / 1024)) / 10;

    files_stat.max_files = max_t(unsigned long, n, NR_FILE);
}
```