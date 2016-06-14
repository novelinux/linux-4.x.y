struct net
========================================

path: include/net/net_namespace.h
```
struct net {
    atomic_t        passive;    /* To decided when the network
                         * namespace should be freed.
                         */
    atomic_t        count;        /* To decided when the network
                         *  namespace should be shut down.
                         */
    spinlock_t        rules_mod_lock;

    atomic64_t        cookie_gen;

    struct list_head    list;        /* list of network namespaces */
    struct list_head    cleanup_list;    /* namespaces on death row */
    struct list_head    exit_list;    /* Use only net_mutex */

    struct user_namespace   *user_ns;    /* Owning user namespace */
    spinlock_t        nsid_lock;
    struct idr        netns_ids;

    struct ns_common    ns;

    struct proc_dir_entry     *proc_net;
    struct proc_dir_entry     *proc_net_stat;

#ifdef CONFIG_SYSCTL
    struct ctl_table_set    sysctls;
#endif

    struct sock         *rtnl;            /* rtnetlink socket */
    struct sock        *genl_sock;

    struct list_head     dev_base_head;
    struct hlist_head     *dev_name_head;
    struct hlist_head    *dev_index_head;
    unsigned int        dev_base_seq;    /* protected by rtnl_mutex */
    int            ifindex;
    unsigned int        dev_unreg_count;

    /* core fib_rules */
    struct list_head    rules_ops;


    struct net_device       *loopback_dev;          /* The loopback */
    struct netns_core    core;
    struct netns_mib    mib;
    struct netns_packet    packet;
    struct netns_unix    unx;
    struct netns_ipv4    ipv4;
#if IS_ENABLED(CONFIG_IPV6)
    struct netns_ipv6    ipv6;
#endif
#if IS_ENABLED(CONFIG_IEEE802154_6LOWPAN)
    struct netns_ieee802154_lowpan    ieee802154_lowpan;
#endif
#if defined(CONFIG_IP_SCTP) || defined(CONFIG_IP_SCTP_MODULE)
    struct netns_sctp    sctp;
#endif
#if defined(CONFIG_IP_DCCP) || defined(CONFIG_IP_DCCP_MODULE)
    struct netns_dccp    dccp;
#endif
#ifdef CONFIG_NETFILTER
    struct netns_nf        nf;
    struct netns_xt        xt;
#if defined(CONFIG_NF_CONNTRACK) || defined(CONFIG_NF_CONNTRACK_MODULE)
    struct netns_ct        ct;
#endif
#if defined(CONFIG_NF_TABLES) || defined(CONFIG_NF_TABLES_MODULE)
    struct netns_nftables    nft;
#endif
#if IS_ENABLED(CONFIG_NF_DEFRAG_IPV6)
    struct netns_nf_frag    nf_frag;
#endif
    struct sock        *nfnl;
    struct sock        *nfnl_stash;
#if IS_ENABLED(CONFIG_NETFILTER_NETLINK_ACCT)
    struct list_head        nfnl_acct_list;
#endif
#endif
#ifdef CONFIG_WEXT_CORE
    struct sk_buff_head    wext_nlevents;
#endif
    struct net_generic __rcu    *gen;

    /* Note : following structs are cache line aligned */
#ifdef CONFIG_XFRM
    struct netns_xfrm    xfrm;
#endif
#if IS_ENABLED(CONFIG_IP_VS)
    struct netns_ipvs    *ipvs;
#endif
#if IS_ENABLED(CONFIG_MPLS)
    struct netns_mpls    mpls;
#endif
    struct sock        *diag_nlsk;
    atomic_t        fnhe_genid;
};
```