# struct qstr

```
/* The hash is always the low bits of hash_len */
#ifdef __LITTLE_ENDIAN
 #define HASH_LEN_DECLARE u32 hash; u32 len
 #define bytemask_from_count(cnt)	(~(~0ul << (cnt)*8))
#else
 #define HASH_LEN_DECLARE u32 len; u32 hash
 #define bytemask_from_count(cnt)	(~(~0ul >> (cnt)*8))
#endif

/*
 * "quick string" -- eases parameter passing, but more importantly
 * saves "metadata" about the string (ie length and the hash).
 *
 * hash comes first so it snuggles against d_parent in the
 * dentry.
 */
struct qstr {
	union {
		struct {
			HASH_LEN_DECLARE;
		};
		u64 hash_len;
	};
	const unsigned char *name;
};
```