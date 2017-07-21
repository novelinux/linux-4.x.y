# worker_pool

```
/*
 * Structure fields follow one of the following exclusion rules.
 *
 * I: Modifiable by initialization/destruction paths and read-only for
 *    everyone else.
 *
 * P: Preemption protected.  Disabling preemption is enough and should
 *    only be modified and accessed from the local cpu.
 *
 * L: pool->lock protected.  Access with pool->lock held.
 *
 * X: During normal operation, modification requires pool->lock and should
 *    be done only from local cpu.  Either disabling preemption on local
 *    cpu or grabbing pool->lock is enough for read access.  If
 *    POOL_DISASSOCIATED is set, it's identical to L.
 *
 * A: pool->attach_mutex protected.
 *
 * PL: wq_pool_mutex protected.
 *
 * PR: wq_pool_mutex protected for writes.  Sched-RCU protected for reads.
 *
 * PW: wq_pool_mutex and wq->mutex protected for writes.  Either for reads.
 *
 * PWR: wq_pool_mutex and wq->mutex protected for writes.  Either or
 *      sched-RCU for reads.
 *
 * WQ: wq->mutex protected.
 *
 * WR: wq->mutex protected for writes.  Sched-RCU protected for reads.
 *
 * MD: wq_mayday_lock protected.
 */

/* struct worker is defined in workqueue_internal.h */

struct worker_pool {
	spinlock_t		lock;		/* the pool lock */
	int			cpu;		/* I: the associated cpu */
	int			node;		/* I: the associated node ID */
	int			id;		/* I: pool ID */
	unsigned int		flags;		/* X: flags */

	unsigned long		watchdog_ts;	/* L: watchdog timestamp */

	struct list_head	worklist;	/* L: list of pending works */
	int			nr_workers;	/* L: total number of workers */

	/* nr_idle includes the ones off idle_list for rebinding */
	int			nr_idle;	/* L: currently idle ones */

	struct list_head	idle_list;	/* X: list of idle workers */
	struct timer_list	idle_timer;	/* L: worker idle timeout */
	struct timer_list	mayday_timer;	/* L: SOS timer for workers */

	/* a workers is either on busy_hash or idle_list, or the manager */
	DECLARE_HASHTABLE(busy_hash, BUSY_WORKER_HASH_ORDER);
						/* L: hash of busy workers */

	/* see manage_workers() for details on the two manager mutexes */
	struct mutex		manager_arb;	/* manager arbitration */
	struct worker		*manager;	/* L: purely informational */
	struct mutex		attach_mutex;	/* attach/detach exclusion */
	struct list_head	workers;	/* A: attached workers */
	struct completion	*detach_completion; /* all workers detached */

	struct ida		worker_ida;	/* worker IDs for task name */

	struct workqueue_attrs	*attrs;		/* I: worker attributes */
	struct hlist_node	hash_node;	/* PL: unbound_pool_hash node */
	int			refcnt;		/* PL: refcnt for unbound pools */

	/*
	 * The current concurrency level.  As it's likely to be accessed
	 * from other CPUs during try_to_wake_up(), put it in a separate
	 * cacheline.
	 */
	atomic_t		nr_running ____cacheline_aligned_in_smp;

	/*
	 * Destruction of pool is sched-RCU protected to allow dereferences
	 * from get_work_pool().
	 */
	struct rcu_head		rcu;
} ____cacheline_aligned_in_smp;
```