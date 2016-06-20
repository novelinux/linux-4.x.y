jbd2_journal_begin_ordered_truncate
========================================

path: fs/jbd2/transaction.c
```
/*
 * File truncate and transaction commit interact with each other in a
 * non-trivial way.  If a transaction writing data block A is
 * committing, we cannot discard the data by truncate until we have
 * written them.  Otherwise if we crashed after the transaction with
 * write has committed but before the transaction with truncate has
 * committed, we could see stale data in block A.  This function is a
 * helper to solve this problem.  It starts writeout of the truncated
 * part in case it is in the committing transaction.
 *
 * Filesystem code must call this function when inode is journaled in
 * ordered mode before truncation happens and after the inode has been
 * placed on orphan list with the new inode size. The second condition
 * avoids the race that someone writes new data and we start
 * committing the transaction after this function has been called but
 * before a transaction for truncate is started (and furthermore it
 * allows us to optimize the case where the addition to orphan list
 * happens in the same transaction as write --- we don't have to write
 * any data in such case).
 */
int jbd2_journal_begin_ordered_truncate(journal_t *journal,
                    struct jbd2_inode *jinode,
                    loff_t new_size)
{
    transaction_t *inode_trans, *commit_trans;
    int ret = 0;

    /* This is a quick check to avoid locking if not necessary */
    if (!jinode->i_transaction)
        goto out;
    /* Locks are here just to force reading of recent values, it is
     * enough that the transaction was not committing before we started
     * a transaction adding the inode to orphan list */
    read_lock(&journal->j_state_lock);
    commit_trans = journal->j_committing_transaction;
    read_unlock(&journal->j_state_lock);
    spin_lock(&journal->j_list_lock);
    inode_trans = jinode->i_transaction;
    spin_unlock(&journal->j_list_lock);
    if (inode_trans == commit_trans) {
        ret = filemap_fdatawrite_range(jinode->i_vfs_inode->i_mapping,
            new_size, LLONG_MAX);
        if (ret)
            jbd2_journal_abort(journal, ret);
    }
out:
    return ret;
}
```