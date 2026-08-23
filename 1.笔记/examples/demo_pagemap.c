#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>

enum {
    PAGEMAP_PRESENT_BIT = 63,
    PAGEMAP_SWAPPED_BIT = 62,
};

static const uint64_t PAGEMAP_PFN_MASK = (UINT64_C(1) << 55) - 1;

static int read_pagemap_entry(int fd, const void *address, long page_size,
                              uint64_t *entry) {
    const uint64_t virtual_page = (uint64_t)(uintptr_t)address /
                                  (uint64_t)page_size;
    const off_t offset = (off_t)(virtual_page * sizeof(*entry));
    const ssize_t bytes = pread(fd, entry, sizeof(*entry), offset);

    if (bytes == (ssize_t)sizeof(*entry)) {
        return 0;
    }
    if (bytes >= 0) {
        errno = EIO;
    }
    return -1;
}

static int print_pagemap_entry(int fd, const unsigned char *base,
                               size_t page_index, long page_size,
                               const char *phase) {
    const unsigned char *address = base + page_index * (size_t)page_size;
    uint64_t entry = 0;

    if (read_pagemap_entry(fd, address, page_size, &entry) != 0) {
        fprintf(stderr, "pread(/proc/self/pagemap): %s\n", strerror(errno));
        return -1;
    }

    const int present = (int)((entry >> PAGEMAP_PRESENT_BIT) & 1U);
    const int swapped = (int)((entry >> PAGEMAP_SWAPPED_BIT) & 1U);
    const uint64_t pfn = entry & PAGEMAP_PFN_MASK;

    printf("%-12s page[%zu] va=%p entry=0x%016" PRIx64
           " present=%d swapped=%d pfn=0x%" PRIx64 "\n",
           phase, page_index, (const void *)address, entry,
           present, swapped, pfn);
    return 0;
}

int main(void) {
    const long page_size = sysconf(_SC_PAGESIZE);
    const size_t page_count = 4;
    unsigned char *pages = MAP_FAILED;
    int fd = -1;

    if (page_size <= 0) {
        fprintf(stderr, "sysconf(_SC_PAGESIZE) failed\n");
        return EXIT_FAILURE;
    }

    pages = mmap(NULL, page_count * (size_t)page_size,
                 PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (pages == MAP_FAILED) {
        fprintf(stderr, "mmap: %s\n", strerror(errno));
        return EXIT_FAILURE;
    }

#ifdef MADV_NOHUGEPAGE
    /* Keep the demonstration page-granular when the kernel supports it. */
    (void)madvise(pages, page_count * (size_t)page_size, MADV_NOHUGEPAGE);
#endif

    fd = open("/proc/self/pagemap", O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "open(/proc/self/pagemap): %s\n", strerror(errno));
        munmap(pages, page_count * (size_t)page_size);
        return EXIT_FAILURE;
    }

    puts("Before touching the anonymous mapping:");
    for (size_t index = 0; index < page_count; ++index) {
        if (print_pagemap_entry(fd, pages, index, page_size,
                                "before") != 0) {
            close(fd);
            munmap(pages, page_count * (size_t)page_size);
            return EXIT_FAILURE;
        }
    }

    /* Fault in two adjacent pages; leave pages 2 and 3 untouched. */
    pages[0] = 0x5a;
    pages[(size_t)page_size] = 0xa5;

    puts("\nAfter touching pages 0 and 1:");
    for (size_t index = 0; index < page_count; ++index) {
        if (print_pagemap_entry(fd, pages, index, page_size,
                                "after") != 0) {
            close(fd);
            munmap(pages, page_count * (size_t)page_size);
            return EXIT_FAILURE;
        }
    }

    puts("\nA present entry with pfn=0 usually means PFN disclosure is "
         "restricted for this caller. Compare pages 0 and 1 only when "
         "nonzero PFNs are visible.");

    close(fd);
    munmap(pages, page_count * (size_t)page_size);
    return EXIT_SUCCESS;
}
