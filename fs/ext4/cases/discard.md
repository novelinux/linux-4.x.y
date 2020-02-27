## 背景

对于异步discard的触发条件，谷歌设置的是如下三个
```
        builder.setRequiresDeviceIdle(true);                   //需要screen off 71分钟
        builder.setRequiresCharging(true);                     //需要正在充电
        builder.setMinimumLatency(timeToMidnight);     //需要到凌晨三点才满足条件，若此时不满足，则delay到条件满足时执行
```

我们优化的的策略是通过改变触发discard的条件，从而提高异步discard的频率。

### 一、基础知识

在进行异步discard触发条件设置前，必须对安卓提供的接口API和代码的逻辑有一定的理解，下面从两个方面描述一下操作前的基础知识

1.安卓提供的接口API

进行修改前，要知道JobScheduler，JobService，JboInfor，JobInfo.Buidler的作用及相互关系，下面我说一下自己的理解。

对于一些需要满足特定条件才能执行的后台任务，Android提供了JobScheduler对这些任务进行调度来减少电量的消耗，使用JobScheduler的时候需要把待执行的后台任务封装到JobService中，然后将此任务提交入JobScheduler中进行调度。而JobInfo.Buidler是用来构造JobInfor对象，从而达到对任务的执行进行条件的设置的作用。JobScheduler对任务进行调度，且条件满足时，则执行JobService.onStartJob（）(JobService提供了名为onStartJob()的接口，供其子类重写onStartJob()方法，此方法内写入后台操作，在被调度执行的时候，即执行JobServic.onStartJob()`)。这么说，有些抽象了，下面结合异步discard的设计逻辑，进行说明。

异步discard就是需要在一些特殊条件下执行的任务，我们可以利用JobInfo.Buidler设置执行的条件（谷歌设置的触发条件如上 背景 所示）。将异步discard的操作封装进入类MountServiceIdler中，为了使异步discard任务能够被JobScheduler调度，使MountServiceIdler继承JobService成为其子类，并在onStartJob()写入具体的后台任务，由此可以在条件满足时执行异步discardc操作。

2.谷歌原有异步discard的程序执行流

onStartJob()                                                              执行 StorageManagerService.runIdleMaintenance(mFinishCallback);

mHandler.sendMessage(mHandler.obtainMessage(H_FSTRIM, callback));

case H_FSTRIM:                                                    执行fstrim操作，完成后使用回调函数，调用 mFinishCallback.run()

mFinishCallback.run()                                            调用scheduleIdlePass(MountServiceIdler.this)，等待时机下次进行trim

scheduleIdlePass(MountServiceIdler.this);           使用JboScheduler对MounServiceIdler进行调度，使用JobInfor.Builder对执行条件进行设置：charging&&idle&&midnight   当调度条件成立时，执行onStartJob()里面的逻辑

进入onStartJob()

.......



二、已有的设置触发条件的接口
每个接口的参数与作用如下：

setPeriodic(long intervalMillis)
Specify that this job should recur with the provided interval, not more than once per period.

setRequiredNetwork(NetworkRequest networkRequest)
Set detailed description of the kind of network your job requires.

setRequiresBatteryNotLow(boolean batteryNotLow)
Specify that to run this job, the device's battery level must not be low.
setRequiresCharging(boolean requiresCharging)
Specify that to run this job, the device must be charging (or be a non-battery-powered device connected to permanent power, such as Android TV devices).
setRequiresDeviceIdle(boolean requiresDeviceIdle)
When set true, ensure that this job will not run if the device is in active use.
setRequiresStorageNotLow(boolean storageNotLow)
Specify that to run this job, the device's available storage must not be low.
setTriggerContentMaxDelay(long durationMs)
Set the maximum total delay (in milliseconds) that is allowed from the first time a content change is detected until the job is scheduled.
setMinimumLatency(long minLatencyMillis)
Specify that this job should be delayed by the provided amount of time.



三、已经进行的一些实验

1.设置周期运行discard操作

这个思路可以利用setMinimumLatency(long minLatencyMillis)函数（参数为毫秒）。在自己的机器上运行，如设置二十分钟进行一次。change入下：

```
   /**
     * Schedule the idle job that will ping the mount service
     */
    public static void scheduleIdlePass(Context context) {
        JobScheduler tm = (JobScheduler) context.getSystemService(Context.JOB_SCHEDULER_SERVICE);

	final long tenMinutes = (long)10 * 60 * 1000;
        JobInfo.Builder builder = new JobInfo.Builder(MOUNT_JOB_ID, sIdleService);
        builder.setRequiresCharging(true);
        builder.setMinimumLatency(tenMinutes);
	tm.schedule(builder.build());
    }
```

刷机验证,使用 adb logcat | grep vold对Trim进行监控，可以达到周期性运行的结果。这种策略的优点是可以频繁的触发异步discard，缺点也很明显，没有考虑对电量的消耗，如果用户在进行频繁的操作时，异步discrad触发，可能会影响用户使用的流畅度。

2.充电情况下，周期性触发discard

这个思路可以利用函数setRequiresCharging(boolean requiresCharging)和setMinimumLatency(long minLatencyMillis)共同完成。这种策略，充电情况下每隔一段时间触发一次异步discard,如果规定时间到达，手机并未处于充电状态，则delay到充电状态满足，触发异步discard.change如下：

刷机验证,使用 adb logcat | grep vold对Trim进行监控，可以达到充电情况下周期性运行的结果。这种策略的优点是相比于谷歌的限制条件，提高了异步discard的执行频率，同时考虑了电量的消耗问题，缺点是在用户频繁进行操作的时候，影响用户体验。

3.满足idle条件下，周期性触发discard
这个思路可以利用setRequiresDeviceIdle(boolean requiresDeviceIdle)和setMinimumLatency(long minLatencyMillis)共同完成。这种策略，在最小时间延迟满足后，进入idle状态即可执行异步discard；或者一直保持在idle状态时，以minLatencyMillis为周期，周期性触发异步discard,change如下：


刷机验证，使用 adb logcat | grep vold对Trim进行监控，可以达到如上描述的结果。这种策略的优点是，在device处于idle状态下进行异步discard，减少对于用户操作的影响，缺点是device idle状态比较难以进入，触发异步discard的频率不会很高。

4.周期性触发，且screen off下方可运行


为了不影响用户在操作手机时的体验，我们倾向于screen off时触发；为了提高触发的频率，我们倾向于周期性试探（比如，每2小时试探一次，若screen off则执行，若screen on减少试探周期的时间）。这是一种我们比较倾向于作为最终策略的设置条件，具体逻辑如下：

1. 设置2小时的检查间隔
2. 时间间隔到的时候，如果是screen off状态，就trim
3. 时间间隔到的时候，如果是screen on的状态，就设置间隔为一半(1小时)再次检查

具体的change如下(实验时为了快速得到结果，设置的初始检查间隔为10分钟，若screen on间隔为5分钟）：

```
    @Override
    public boolean onStartJob(JobParameters params) {
        // First have the activity manager do its idle maintenance.  (Yes this job
        // is really more than just mount, some day it should be renamed to be system
        // idleer).
        try {
            ActivityManager.getService().performIdleMaintenance();
        } catch (RemoteException e) {
        }
        // The mount service will run an fstrim operation asynchronously
        // on a designated separate thread, so we provide it with a callback
        // that lets us cleanly end our idle timeslice.  It's safe to call
        // finishIdle() from any thread.
        mJobParams = params;

        if (MountServiceIdlerInjector.canExecuteAsyncDiscard(this)) {
            MountServiceIdlerInjector.resetNextTrimDuration();
            StorageManagerService ms = StorageManagerService.sSelf;
            if (ms != null) {
                synchronized (mFinishCallback) {
                    mStarted = true;
                }
                ms.runIdleMaintenance(mFinishCallback);
            }
            return ms != null;
        } else {
            // halve waiting time bacause of unsatisfied conditions
            // we prefer executing async discard frequently
            MountServiceIdlerInjector.halveNextTrimDuration();
            scheduleIdlePass(MountServiceIdler.this);
            return false;
        }
    }
```