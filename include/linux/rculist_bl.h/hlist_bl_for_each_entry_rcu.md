# hlist_bl_for_each_entry_rcu

```
static inline struct hlist_bl_node *hlist_bl_first_rcu(struct hlist_bl_head *h)
{
	return (struct hlist_bl_node *)
		((unsigned long)rcu_dereference_check(h->first, hlist_bl_is_locked(h)) & ~LIST_BL_LOCKMASK);
}

/**
 * hlist_bl_for_each_entry_rcu - iterate over rcu list of given type
 * @tpos:	the type * to use as a loop cursor.
 * @pos:	the &struct hlist_bl_node to use as a loop cursor.
 * @head:	the head for your list.
 * @member:	the name of the hlist_bl_node within the struct.
 *
 */
#define hlist_bl_for_each_entry_rcu(tpos, pos, head, member)		\
	for (pos = hlist_bl_first_rcu(head);				\
		pos &&							\
		({ tpos = hlist_bl_entry(pos, typeof(*tpos), member); 1; }); \
		pos = rcu_dereference_raw(pos->next))

#endif
```
