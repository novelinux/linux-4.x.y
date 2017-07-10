# Using the TRACE_EVENT() macro (Part 1)

## Did you know...?
LWN.net is a subscriber-supported publication; we rely on subscribers to keep the entire operation going. Please help out by buying a subscription and keeping LWN on the net.

March 24, 2010
This article was contributed by Steven Rostedt
Throughout the history of Linux, people have been wanting to add static tracepoints — functions that record data at a specific site in the kernel for later retrieval — to the kernel. Those efforts weren't very successful because of the fear that tracepoints would sacrifice performance. Unlike the Ftrace function tracer, a tracepoint can record more than just the function being entered. A tracepoint can record local variables of the function. Over time, various strategies for adding tracepoints have been tried, with varying success, and the TRACE_EVENT() macro is the latest way to add kernel tracepoints.

## History

Mathieu Desnoyers worked on adding a very low overhead tracer hook called trace markers. Even though the trace markers solved the performance issue by using cleverly crafted macros, the information that the trace marker would record was embedded at the location in the core kernel as a printf format. This upset several core kernel developers as it made the core kernel code look like debug code was left scattered throughout.

In trying to appease the kernel developers, Mathieu came up with tracepoints. The tracepoint included a function call in the kernel code that, when enabled, would call a callback function passing the parameters of the tracepoint to that function as if the callback function was called with those parameters. This was much better than the trace markers since it allowed the passing of type casted pointers that the callback functions could dereference, as opposed to the marker interface, which required the callback function to parse a string. With the tracepoint, the callback function could efficiently take whatever it needed from the structures.

Although this was an improvement over trace markers, it was still too tedious for developers to create a callback for every tracepoint they wanted to add, so that a tracer would output its data. The kernel needed a more automated way to connect a tracer to the tracepoints. That would require automating the creation of the callback and also format its data, much like what the trace marker did, but it should be done in the callback, and not at the tracepoint site in the kernel code.

To solve this issue of automating the tracepoints, the TRACE_EVENT() macro was born. Inspired by Tom Zanussi's zedtrace, this macro was specifically made to allow a developer to add tracepoints to their subsystem and have Ftrace automatically be able to trace them. The developer need not understand how Ftrace works, they only need to create their tracepoint using the TRACE_EVENT() macro. In addition, they need to follow some guidelines in how to create a header file and they would gain full access to the Ftrace tracer. Another objective of the design of the TRACE_EVENT() macro was to not couple it to Ftrace or any other tracer. It is agnostic to the tracers that use it, which is apparent now that TRACE_EVENT() is also used by perf, LTTng and SystemTap.

The anatomy of the TRACE_EVENT() macro

Automating tracepoints had various requirements that must be fulfilled:

It must create a tracepoint that can be placed in the kernel code.
It must create a callback function that can be hooked to this tracepoint.
The callback function must be able to record the data passed to it into the tracer ring buffer in the fastest way possible.
It must create a function that can parse the data recorded to the ring buffer and translate it to a human readable format that the tracer can display to a user.
To accomplish that, the TRACE_EVENT() macro is broken into six components, which correspond to the parameters of the macro:

   TRACE_EVENT(name, proto, args, struct, assign, print)
name - the name of the tracepoint to be created.
prototype - the prototype for the tracepoint callbacks
args - the arguments that match the prototype.
struct - the structure that a tracer could use (but is not required to) to store the data passed into the tracepoint.
assign - the C-like way to assign the data to the structure.
print - the way to output the structure in human readable ASCII format.
A good example of a tracepoint definition, for sched_switch, can be found here. That definition will be used below to describe each of the parts of TRACE_EVENT() macro.

All parameters except the first one are encapsulated with another macro (TP_PROTO, TP_ARGS, TP_STRUCT__entry, TP_fast_assign and TP_printk). These macros give more control in processing and also allow commas to be used within the TRACE_EVENT() macro.

## Name

The first parameter is the name.

   TRACE_EVENT(sched_switch,
This is the name used to call this tracepoint. The actual tracepoint that is used has trace_ prefixed to the name (ie. trace_sched_switch).

## Prototype

The next parameter is the prototype.

    TP_PROTO(struct rq *rq, struct task_struct *prev, struct task_struct *next),
The prototype is written as if you were to declare the tracepoint directly:

    trace_sched_switch(struct rq *rq, struct task_struct *prev,
                       struct task_struct *next);
It is used as the prototype for both the tracepoint added to the kernel code and for the callback function. Remember, a tracepoint calls the callback functions as if the callback functions were being called at the location of the tracepoint.

## Arguments

The third parameter is the arguments used by the prototype.

    TP_ARGS(rq, prev, next),
It may seem strange that this is needed, but it is not only required by the TRACE_EVENT() macro, it is also required by the tracepoint infrastructure underneath. The tracepoint code, when activated, will call the callback functions (more than one callback may be assigned to a given tracepoint). The macro that creates the tracepoint must have access to both the prototype and the arguments. Below is an illustration of what a tracepoint macro would need to accomplish this:

    #define TRACE_POINT(name, proto, args) \
       void trace_##name(proto)            \
       {                                   \
               if (trace_##name##_active)  \
                       callback(args);     \
       }

## Structure

The fourth parameter is a bit more complex.

    TP_STRUCT__entry(
		__array(	char,	prev_comm,	TASK_COMM_LEN	)
		__field(	pid_t,	prev_pid			)
		__field(	int,	prev_prio			)
		__field(	long,	prev_state			)
		__array(	char,	next_comm,	TASK_COMM_LEN	)
		__field(	pid_t,	next_pid			)
		__field(	int,	next_prio			)
    ),
This parameter describes the structure layout of the data that will be stored in the tracer's ring buffer. Each element of the structure is defined by another macro. These macros are used to automate the creation of a structure and are not function-like. Notice that the macros are not separated by any delimiter (no comma nor semicolon).

The macros used by the sched_switch tracepoint are:

__field(type, name) - this defines a normal structure element, like int var; where type is int and name is var.
__array(type, name, len) - this defines an array item, equivalent to int name[len]; where the type is int the name of the array is array and the number of items in the array is len.
There are other element macros that will be described in a later article. The definition from the sched_switch tracepoint would produce a structure that looks like:

    struct {
	      char   prev_comm[TASK_COMM_LEN];
	      pid_t  prev_pid;
	      int    prev_prio;
	      long   prev_state;
	      char   next_comm[TASK_COMM_LEN];
	      pid_t  next_pid;
	      int    next_prio;
    };
Note that the spacing used in the TP_STRUCT__entry definition breaks the rules outlined by checkpatch.pl. That is done because these macros are not function-like but, instead, are used to define a structure. The spacing follows the rules of structure spacing and not of function spacing, so that the names line up in the structure declaration. Needless to say, checkpatch.pl fails horribly when processing changes to TRACE_EVENT() definitions.

## Assignment

The fifth parameter defines the way the data from the parameters is saved to the ring buffer.

    TP_fast_assign(
		memcpy(__entry->next_comm, next->comm, TASK_COMM_LEN);
		__entry->prev_pid	= prev->pid;
		__entry->prev_prio	= prev->prio;
		__entry->prev_state	= prev->state;
		memcpy(__entry->prev_comm, prev->comm, TASK_COMM_LEN);
		__entry->next_pid	= next->pid;
		__entry->next_prio	= next->prio;
    ),
The code within the TP_fast_assign() is normal C code. A special variable __entry represents the pointer to a structure type defined by TP_STRUCT__entry and points directly into the ring buffer. The TP_fast_assign is used to fill all fields created in TP_STRUCT__entry. The variable names of the parameters defined by TP_PROTO and TP_ARGS can then be used to assign the appropriate data into the __entry structure.

## Print

The last parameter defines how a printk() can be used to print out the fields from the TP_STRUCT__entry structure.

	TP_printk("prev_comm=%s prev_pid=%d prev_prio=%d prev_state=%s ==> " \
 		  "next_comm=%s next_pid=%d next_prio=%d",
		__entry->prev_comm, __entry->prev_pid, __entry->prev_prio,
		__entry->prev_state ?
		  __print_flags(__entry->prev_state, "|",
				{ 1, "S"} , { 2, "D" }, { 4, "T" }, { 8, "t" },
				{ 16, "Z" }, { 32, "X" }, { 64, "x" },
				{ 128, "W" }) : "R",
		__entry->next_comm, __entry->next_pid, __entry->next_prio)
Once again the variable __entry is used to reference the pointer to the structure that contains the data. The format string is just like any other printf format. The __print_flags() is part of a set of helper functions that come with TRACE_EVENT(), and will be covered in another article. Do not create new tracepoint-specific helpers, because that will confuse user-space tools that know about the TRACE_EVENT() helper macros but will not know how to handle ones created for individual tracepoints.

## Format file

The sched_switch TRACE_EVENT() macro produces the following format file in /sys/kernel/debug/tracing/events/sched/sched_switch/format:

   name: sched_switch
   ID: 33
   format:
	field:unsigned short common_type;	offset:0;	size:2;
	field:unsigned char common_flags;	offset:2;	size:1;
	field:unsigned char common_preempt_count;	offset:3;	size:1;
	field:int common_pid;	offset:4;	size:4;
	field:int common_lock_depth;	offset:8;	size:4;

	field:char prev_comm[TASK_COMM_LEN];	offset:12;	size:16;
	field:pid_t prev_pid;	offset:28;	size:4;
	field:int prev_prio;	offset:32;	size:4;
	field:long prev_state;	offset:40;	size:8;
	field:char next_comm[TASK_COMM_LEN];	offset:48;	size:16;
	field:pid_t next_pid;	offset:64;	size:4;
	field:int next_prio;	offset:68;	size:4;

   print fmt: "task %s:%d [%d] (%s) ==> %s:%d [%d]", REC->prev_comm, REC->prev_pid,
   REC->prev_prio, REC->prev_state ? __print_flags(REC->prev_state, "|", { 1, "S"} ,
   { 2, "D" }, { 4, "T" }, { 8, "t" }, { 16, "Z" }, { 32, "X" }, { 64, "x" }, { 128,
   "W" }) : "R", REC->next_comm, REC->next_pid, REC->next_prio
Note: Newer kernels may also display a signed entry for each field.

Notice that __entry is replaced with REC in the format file. The first set of fields (common_*) are not from the TRACE_EVENT() macro, but are added to all events by Ftrace, which created this format file, other tracers could add different fields. The format file provides user-space tools the information needed to parse the binary output containing sched_switch entries.

## The header file

The TRACE_EVENT() macro cannot just be placed anywhere in the expectation that it will work with Ftrace or any other tracer. The header file that contains the TRACE_EVENT() macro must follow a certain format. These header files typically are located in the include/trace/events directory but do not need to be. If they are not located in this directory, then other configurations are necessary.

The first line in the TRACE_EVENT() header is not the normal #ifdef _TRACE_SCHED_H, but instead has:

   #undef TRACE_SYSTEM
   #define TRACE_SYSTEM sched

   #if !defined(_TRACE_SCHED_H) || defined(TRACE_HEADER_MULTI_READ)
   #define _TRACE_SCHED_H
This example is for scheduler trace events, other event headers would use something other than sched and _TRACE_SCHED_H. The TRACE_HEADER_MULTI_READ test allows this file to be included more than once; this is important for the processing of the TRACE_EVENT() macro. The TRACE_SYSTEM must also be defined for the file and must be outside the guard of the #if. The TRACE_SYSTEM defines what group the TRACE_EVENT() macros in the file belong to. This is also the directory name that the events will be grouped under in the debugfs tracing/events directory. This grouping is important for Ftrace as it allows the user to enable or disable events by group.

The file then includes any headers required by the contents of the TRACE_EVENT() macro. (e.g. #include <linux/sched.h>). The tracepoint.h file is required.

   #include <linux/tracepoint.h>
All the trace events can now be defined with TRACE_EVENT() macros. Please include comments that describe the tracepoint above the TRACE_EVENT() macros. Look at include/trace/events/sched.h as an example. The file ends with:

   #endif /* _TRACE_SCHED_H */

   /* This part must be outside protection */
   #include <trace/define_trace.h>
The define_trace.h is where all the magic lies in creating the tracepoints. The explanation of how this file works will be left to another article. For now, it is sufficient to know that this file must be included at the bottom of the trace header file outside the protection of the #endif.

## Using the tracepoint

Defining the tracepoint is meaningless if it is not used anywhere. To use the tracepoint, the trace header must be included, but one C file (and only one) must also define CREATE_TRACE_POINTS before including the trace. This will cause the define_trace.h to create the necessary functions needed to produce the tracing events. In kernel/sched.c the following is defined:

   #define CREATE_TRACE_POINTS
   #include <trace/events/sched.h>
If another file needs to use tracepoints that were defined in the trace file, then it only needs to include the trace file, and does not need to define CREATE_TRACE_POINTS. Defining it more than once for the same header file will cause linker errors when building. For example, in kernel/fork.c only the header file is included:

   #include <trace/events/sched.h>
Finally, the tracepoint is used in the code just as it was defined in the TRACE_EVENT() macro:

   static inline void
   context_switch(struct rq *rq, struct task_struct *prev,
	          struct task_struct *next)
   {
	   struct mm_struct *mm, *oldmm;

	   prepare_task_switch(rq, prev, next);
	   trace_sched_switch(rq, prev, next);
	   mm = next->mm;
	   oldmm = prev->active_mm;
Coming soon

This article explained all that is needed to create a basic tracepoint within the core kernel code. Part 2 will describe how to consolidate tracepoints to keep the tracing footprint small, along with information about the TP_STRUCT__entry macros and TP_printk helper functions (like __print_flags). Part 3 will look at defining tracepoints outside of the include/trace/events directory (for modules and architecture-specific tracepoints) as well as a look at how the TRACE_EVENT() macro does its magic. Both articles will have a few practical examples of how to use tracepoints. Stay tuned ...

# ORIGINAL URL

https://lwn.net/Articles/379903/