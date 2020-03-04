#ifndef LOG_TAG
#define LOG_TAG "mybpfloader"
#endif

#include <arpa/inet.h>
#include <dirent.h>
#include <elf.h>
#include <error.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/bpf.h>
#include <linux/unistd.h>
#include <net/if.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <android-base/properties.h>
#include <android-base/stringprintf.h>
#include <android-base/strings.h>
#include <android-base/unique_fd.h>
#include <libbpf_android.h>
#include <log/log.h>
#include <netdutils/Misc.h>
#include <netdutils/Slice.h>
#include "bpf/BpfUtils.h"
#include "bpf/BpfMap.h"

using android::base::EndsWith;
using android::base::unique_fd;
using std::string;

const char *tp_prog_path = "/sys/fs/bpf/prog_bpf_load_tp_prog_tracepoint_sched_sched_switch";
const char *tp_map_path = "/sys/fs/bpf/map_bpf_load_tp_prog_cpu_pid_map";

constexpr uint32_t KEY = 0;

int main(int argc, char *argv[]) {
  if (argc < 2) {
    return 1;
  }

  int ret = android::bpf::loadProg(argv[1]);
  ALOGI("Attempted load object: %s, ret: %s", argv[1], std::strerror(-ret));

  // Attach tracepoint and wait for 4 seconds
  int mProgFd = bpf_obj_get(tp_prog_path);
  int mMapFd = bpf_obj_get(tp_map_path);
  ret = bpf_attach_tracepoint(mProgFd, "sched", "sched_switch");
  sleep(4);

  // Read the map to find the last PID that ran on CPU 0
  android::bpf::BpfMap<uint32_t, uint32_t> myMap(mMapFd);
  android::netdutils::StatusOr<uint32_t> v = myMap.readValue(KEY);
  printf("last PID running on CPU %d is %u\n", 0, v.value());

  return 0;
}
