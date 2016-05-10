find_next_best_node
========================================

path: mm/page_alloc.c
```
#define MAX_NODE_LOAD (nr_online_nodes)
static int node_load[MAX_NUMNODES];

/**
 * find_next_best_node - find the next node that should appear in a given node's fallback list
 * @node: node whose fallback list we're appending
 * @used_node_mask: nodemask_t of already used nodes
 *
 * We use a number of factors to determine which is the next node that should
 * appear on a given node's fallback list.  The node should not have appeared
 * already in @node's fallback list, and it should be the next closest node
 * according to the distance array (which contains arbitrary distance values
 * from each node to each node in the system), and should also prefer nodes
 * with no CPUs, since presumably they'll have very little allocation pressure
 * on them otherwise.
 * It returns -1 if no node is found.
 */
static int find_next_best_node(int node, nodemask_t *used_node_mask)
{
    int n, val;
    int min_val = INT_MAX;
    int best_node = NUMA_NO_NODE;
    const struct cpumask *tmp = cpumask_of_node(0);

    /* Use the local node if we haven't already */
    if (!node_isset(node, *used_node_mask)) {
        node_set(node, *used_node_mask);
        return node;
    }

    for_each_node_state(n, N_MEMORY) {

        /* Don't want a node to appear more than once */
        if (node_isset(n, *used_node_mask))
            continue;

        /* Use the distance array to find the distance */
        val = node_distance(node, n);

        /* Penalize nodes under us ("prefer the next node") */
        val += (n < node);

        /* Give preference to headless and unused nodes */
        tmp = cpumask_of_node(n);
        if (!cpumask_empty(tmp))
            val += PENALTY_FOR_NODE_WITH_CPUS;

        /* Slight preference for less loaded node */
        val *= (MAX_NODE_LOAD*MAX_NUMNODES);
        val += node_load[n];

        if (val < min_val) {
            min_val = val;
            best_node = n;
        }
    }

    if (best_node >= 0)
        node_set(best_node, *used_node_mask);

    return best_node;
}
```