getname_flags
========================================

path: fs/namei.c
```
/* In order to reduce some races, while at the same time doing additional
 * checking and hopefully speeding things up, we copy filenames to the
 * kernel data space before using them..
 *
 * POSIX.1 2.4: an empty pathname is invalid (ENOENT).
 * PATH_MAX includes the nul terminator --RR.
 */

#define EMBEDDED_NAME_MAX    (PATH_MAX - offsetof(struct filename, iname))

struct filename *
getname_flags(const char __user *filename, int flags, int *empty)
{
    struct filename *result;
    char *kname;
    int len;

    result = audit_reusename(filename);
    if (result)
        return result;

    result = __getname();
    if (unlikely(!result))
        return ERR_PTR(-ENOMEM);

    /*
     * First, try to embed the struct filename inside the names_cache
     * allocation
     */
    kname = (char *)result->iname;
    result->name = kname;

    len = strncpy_from_user(kname, filename, EMBEDDED_NAME_MAX);
    if (unlikely(len < 0)) {
        __putname(result);
        return ERR_PTR(len);
    }

    /*
     * Uh-oh. We have a name that's approaching PATH_MAX. Allocate a
     * separate struct filename so we can dedicate the entire
     * names_cache allocation for the pathname, and re-do the copy from
     * userland.
     */
    if (unlikely(len == EMBEDDED_NAME_MAX)) {
        const size_t size = offsetof(struct filename, iname[1]);
        kname = (char *)result;

        /*
         * size is chosen that way we to guarantee that
         * result->iname[0] is within the same object and that
         * kname can't be equal to result->iname, no matter what.
         */
        result = kzalloc(size, GFP_KERNEL);
        if (unlikely(!result)) {
            __putname(kname);
            return ERR_PTR(-ENOMEM);
        }
        result->name = kname;
        len = strncpy_from_user(kname, filename, PATH_MAX);
        if (unlikely(len < 0)) {
            __putname(kname);
            kfree(result);
            return ERR_PTR(len);
        }
        if (unlikely(len == PATH_MAX)) {
            __putname(kname);
            kfree(result);
            return ERR_PTR(-ENAMETOOLONG);
        }
    }

    result->refcnt = 1;
    /* The empty path is special. */
    if (unlikely(!len)) {
        if (empty)
            *empty = 1;
        if (!(flags & LOOKUP_EMPTY)) {
            putname(result);
            return ERR_PTR(-ENOENT);
        }
    }

    result->uptr = filename;
    result->aname = NULL;
    audit_getname(result);
    return result;
}
```