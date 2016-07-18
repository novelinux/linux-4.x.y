create_elf_tables
========================================

Arguments
----------------------------------------

path: fs/binfmt_elf.c
```
static int
create_elf_tables(struct linux_binprm *bprm, struct elfhdr *exec,
        unsigned long load_addr, unsigned long interp_load_addr)
{
    unsigned long p = bprm->p;
    int argc = bprm->argc;
    int envc = bprm->envc;
    elf_addr_t __user *argv;
    elf_addr_t __user *envp;
    elf_addr_t __user *sp;
    elf_addr_t __user *u_platform;
    elf_addr_t __user *u_base_platform;
    elf_addr_t __user *u_rand_bytes;
    const char *k_platform = ELF_PLATFORM;
    const char *k_base_platform = ELF_BASE_PLATFORM;
    unsigned char k_rand_bytes[16];
    int items;
    elf_addr_t *elf_info;
    int ei_index = 0;
    const struct cred *cred = current_cred();
    struct vm_area_struct *vma;
```

u_platform
----------------------------------------

```
    /*
     * In some cases (e.g. Hyper-Threading), we want to avoid L1
     * evictions by the processes running on the same package. One
     * thing we can do is to shuffle the initial stack for them.
     */

    p = arch_align_stack(p);

    /*
     * If this architecture has a platform capability string, copy it
     * to userspace.  In some cases (Sparc), this info is impossible
     * for userspace to get any other way, in others (i386) it is
     * merely difficult.
     */
    u_platform = NULL;
    if (k_platform) {
        size_t len = strlen(k_platform) + 1;

        u_platform = (elf_addr_t __user *)STACK_ALLOC(p, len);
        if (__copy_to_user(u_platform, k_platform, len))
            return -EFAULT;
    }
```

u_base_platform
----------------------------------------

```
    /*
     * If this architecture has a "base" platform capability
     * string, copy it to userspace.
     */
    u_base_platform = NULL;
    if (k_base_platform) {
        size_t len = strlen(k_base_platform) + 1;

        u_base_platform = (elf_addr_t __user *)STACK_ALLOC(p, len);
        if (__copy_to_user(u_base_platform, k_base_platform, len))
            return -EFAULT;
    }
```

u_rand_bytes
----------------------------------------

```
    /*
     * Generate 16 random bytes for userspace PRNG seeding.
     */
    get_random_bytes(k_rand_bytes, sizeof(k_rand_bytes));
    u_rand_bytes = (elf_addr_t __user *)
               STACK_ALLOC(p, sizeof(k_rand_bytes));
    if (__copy_to_user(u_rand_bytes, k_rand_bytes, sizeof(k_rand_bytes)))
        return -EFAULT;
```

current->mm->saved_auxv
----------------------------------------

```
    /* Create the ELF interpreter info */
    elf_info = (elf_addr_t *)current->mm->saved_auxv;
    /* update AT_VECTOR_SIZE_BASE if the number of NEW_AUX_ENT() changes */
#define NEW_AUX_ENT(id, val) \
    do { \
        elf_info[ei_index++] = id; \
        elf_info[ei_index++] = val; \
    } while (0)

#ifdef ARCH_DLINFO
    /*
     * ARCH_DLINFO must come first so PPC can do its special alignment of
     * AUXV.
     * update AT_VECTOR_SIZE_ARCH if the number of NEW_AUX_ENT() in
     * ARCH_DLINFO changes
     */
    ARCH_DLINFO;
#endif
    NEW_AUX_ENT(AT_HWCAP, ELF_HWCAP);
    NEW_AUX_ENT(AT_PAGESZ, ELF_EXEC_PAGESIZE);
    NEW_AUX_ENT(AT_CLKTCK, CLOCKS_PER_SEC);
    NEW_AUX_ENT(AT_PHDR, load_addr + exec->e_phoff);
    NEW_AUX_ENT(AT_PHENT, sizeof(struct elf_phdr));
    NEW_AUX_ENT(AT_PHNUM, exec->e_phnum);
    NEW_AUX_ENT(AT_BASE, interp_load_addr);
    NEW_AUX_ENT(AT_FLAGS, 0);
    NEW_AUX_ENT(AT_ENTRY, exec->e_entry);
    NEW_AUX_ENT(AT_UID, from_kuid_munged(cred->user_ns, cred->uid));
    NEW_AUX_ENT(AT_EUID, from_kuid_munged(cred->user_ns, cred->euid));
    NEW_AUX_ENT(AT_GID, from_kgid_munged(cred->user_ns, cred->gid));
    NEW_AUX_ENT(AT_EGID, from_kgid_munged(cred->user_ns, cred->egid));
     NEW_AUX_ENT(AT_SECURE, security_bprm_secureexec(bprm));
    NEW_AUX_ENT(AT_RANDOM, (elf_addr_t)(unsigned long)u_rand_bytes);
#ifdef ELF_HWCAP2
    NEW_AUX_ENT(AT_HWCAP2, ELF_HWCAP2);
#endif
    NEW_AUX_ENT(AT_EXECFN, bprm->exec);
    if (k_platform) {
        NEW_AUX_ENT(AT_PLATFORM,
                (elf_addr_t)(unsigned long)u_platform);
    }
    if (k_base_platform) {
        NEW_AUX_ENT(AT_BASE_PLATFORM,
                (elf_addr_t)(unsigned long)u_base_platform);
    }
    if (bprm->interp_flags & BINPRM_FLAGS_EXECFD) {
        NEW_AUX_ENT(AT_EXECFD, bprm->interp_data);
    }
#undef NEW_AUX_ENT
    /* AT_NULL is zero; clear the rest too */
    memset(&elf_info[ei_index], 0,
           sizeof current->mm->saved_auxv - ei_index * sizeof elf_info[0]);

    /* And advance past the AT_NULL entry.  */
    ei_index += 2;
```

sp
----------------------------------------

```
    sp = STACK_ADD(p, ei_index);

    items = (argc + 1) + (envc + 1) + 1;
    bprm->p = STACK_ROUND(sp, items);

    /* Point sp at the lowest address on the stack */
#ifdef CONFIG_STACK_GROWSUP
    sp = (elf_addr_t __user *)bprm->p - items - ei_index;
    bprm->exec = (unsigned long)sp; /* XXX: PARISC HACK */
#else
    sp = (elf_addr_t __user *)bprm->p;
#endif
```

find_extend_vma
----------------------------------------

```
    /*
     * Grow the stack manually; some architectures have a limit on how
     * far ahead a user-space access may be in order to grow the stack.
     */
    vma = find_extend_vma(current->mm, bprm->p);
    if (!vma)
        return -EFAULT;
```

argv, envp
----------------------------------------

```
    /* Now, let's put argc (and argv, envp if appropriate) on the stack */
    if (__put_user(argc, sp++))
        return -EFAULT;
    argv = sp;
    envp = argv + argc + 1;

    /* Populate argv and envp */
    p = current->mm->arg_end = current->mm->arg_start;
    while (argc-- > 0) {
        size_t len;
        if (__put_user((elf_addr_t)p, argv++))
            return -EFAULT;
        len = strnlen_user((void __user *)p, MAX_ARG_STRLEN);
        if (!len || len > MAX_ARG_STRLEN)
            return -EINVAL;
        p += len;
    }
    if (__put_user(0, argv))
        return -EFAULT;
    current->mm->arg_end = current->mm->env_start = p;
    while (envc-- > 0) {
        size_t len;
        if (__put_user((elf_addr_t)p, envp++))
            return -EFAULT;
        len = strnlen_user((void __user *)p, MAX_ARG_STRLEN);
        if (!len || len > MAX_ARG_STRLEN)
            return -EINVAL;
        p += len;
    }
    if (__put_user(0, envp))
        return -EFAULT;
    current->mm->env_end = p;

    /* Put the elf_info on the stack in the right place.  */
    sp = (elf_addr_t __user *)envp + 1;
    if (copy_to_user(sp, elf_info, ei_index * sizeof(elf_addr_t)))
        return -EFAULT;
    return 0;
}
```

User Stack
----------------------------------------

```
position            content                     size (bytes) + comment
------------------------------------------------------------------------
                    [ u_platform ]

                    [ u_base_platform ]

                    [ u_rand_bytes ]

                    [ argc = number of args ]     4
                    [ argv[0] (pointer) ]         4   (program name)
                    [ argv[1] (pointer) ]         4
                    [ argv[..] (pointer) ]        4 * x
                    [ argv[n - 1] (pointer) ]     4
                    [ argv[n] (pointer) ]         4   (= NULL)

                    [ envp[0] (pointer) ]         4
                    [ envp[1] (pointer) ]         4
                    [ envp[..] (pointer) ]        4
                    [ envp[term] (pointer) ]      4   (= NULL)

                    [ auxv[0] (Elf32_auxv_t) ]    8
                    [ auxv[1] (Elf32_auxv_t) ]    8
                    [ auxv[..] (Elf32_auxv_t) ]   8
                    [ auxv[term] (Elf32_auxv_t) ] 8   (= AT_NULL vector)

                    [ padding ]                   0 - 16

                    [ argument ASCIIZ strings ]   >= 0
                    [ environment ASCIIZ str. ]   >= 0

  (0xbffffffc)      [ end marker ]                4   (= NULL)
  (0xc0000000)      < top of stack >              0   (virtual)
```