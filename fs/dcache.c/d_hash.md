# d_hash

哈希表有数组dentry_hashtable表示，其中每一个元素都是一个指向具有相同键值的目录项对象链表的指针。
数组的大小取决于系统中物理内存的大小。实际的哈希值由d_hash()计算，它是内核提供给文件系统的唯一的
一个哈希函数。查找哈希表要通过d_lookup()函数，如果该函数在dcache中发现了与其相匹配的目录项对像，
则匹配对象被返回；否则，返回NULL指针。dcache在一定意义上也提供了对索引节点的缓存。和目录项对象
相关的索引节点对象不会被释放，因为目录项会让相关索引节点的使用计数为正，这样就可以确保索引节点
留在内存中。只要目录项被缓存，其相应的索引节点也就被缓存了。

```
/*
 * This is the single most critical data structure when it comes
 * to the dcache: the hashtable for lookups. Somebody should try
 * to make this good - I've just made it work.
 *
 * This hash-function tries to avoid losing too many bits of hash
 * information, yet avoid using a prime hash-size or similar.
 */

static unsigned int d_hash_mask __read_mostly;
static unsigned int d_hash_shift __read_mostly;

static struct hlist_bl_head *dentry_hashtable __read_mostly;

static inline struct hlist_bl_head *d_hash(unsigned int hash)
{
        return dentry_hashtable + (hash >> (32 - d_hash_shift));
}
```