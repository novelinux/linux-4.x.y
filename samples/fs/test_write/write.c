#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

static int64_t file_size(int fd)
{
    struct stat st;
    int ret;

    ret = fstat(fd, &st);

    return ret ? -1 : st.st_size;
}

static void *load_fd(int fd, unsigned *_sz)
{
    char *data;
    int sz;
    int errno_tmp;

    data = 0;

    sz = file_size(fd);
    if (sz < 0) {
        goto oops;
    }

    data = (char*) malloc(sz);
    if(data == 0) goto oops;

    if(read(fd, data, sz) != sz) goto oops;
    close(fd);

    if(_sz) *_sz = sz;
    return data;

oops:
    errno_tmp = errno;
    close(fd);
    if(data != 0) free(data);
    errno = errno_tmp;
    return 0;
}

static void *load_file(const char *fn, unsigned *_sz)
{
    int fd;

    fd = open(fn, O_RDONLY);
    if(fd < 0) return 0;

    return load_fd(fd, _sz);
}

// Keep writing until done or EOF
ssize_t writeall(int fd, void *buf, size_t len)
{
    size_t count = 0;
    while (count<len) {
        int i = write(fd, count+(char *)buf, len-count);
        if (i<1) return i;
        count += i;
    }

    return count;
}

int main(int argc, char *argv[])
{
    unsigned int file_size;
    char *data = load_file(argv[1], &file_size);
    if (data == NULL) {
        fprintf(stderr, "load '%s' failed: %s\n", argv[1], strerror(errno));
        return 1;
    }

    int fd = open(argv[2], O_CREAT | O_TRUNC | O_WRONLY, 0644);
    if (fd < 0) {
        fprintf(stderr, "open '%s' failed: %s\n", argv[2], strerror(errno));
        return 1;
    }
    fprintf(stderr, "wrinting '%lu' ...\n", file_size);
    if (writeall(fd, data, file_size) != file_size) {
        perror("write failed");
        free(data);
        return 1;
    }
    free(data);
    close(fd);

    return 0;
}
