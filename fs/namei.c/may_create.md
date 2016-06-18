may_create
========================================

path: fs/namei.c
```
/* Check whether we can create an object with dentry child in directory
 *  dir.
 *  1. We can't do it if child already exists (open has special treatment for
 *     this case, but since we are inlined it's OK)
 *  2. We can't do it if dir is read-only (done in permission())
 *  3. We should have write and exec permissions on dir
 *  4. We can't do it if dir is immutable (done in permission())
 */
static inline int may_create(struct inode *dir, struct dentry *child)
{
    audit_inode_child(dir, child, AUDIT_TYPE_CHILD_CREATE);
    if (child->d_inode)
        return -EEXIST;
    if (IS_DEADDIR(dir))
        return -ENOENT;
    return inode_permission(dir, MAY_WRITE | MAY_EXEC);
}
```
