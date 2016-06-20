__ext4_journal_start_sb
========================================

path: fs/ext4/ext4_jbd2.c
```
handle_t *__ext4_journal_start_sb(struct super_block *sb, unsigned int line,
                  int type, int blocks, int rsv_blocks)
{
    journal_t *journal;
    int err;

    trace_ext4_journal_start(sb, blocks, rsv_blocks, _RET_IP_);
    err = ext4_journal_check_start(sb);
    if (err < 0)
        return ERR_PTR(err);

    journal = EXT4_SB(sb)->s_journal;
    if (!journal)
        return ext4_get_nojournal();
    return jbd2__journal_start(journal, blocks, rsv_blocks, GFP_NOFS,
                   type, line);
}
```
