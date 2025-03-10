// lsm-block.bpf.c
#include "vmlinux.h"
#include <bpf/bpf_core_read.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "GPL";

#define EPERM 1
#define AF_INET 2

const __u32 blockme = 16843009; // 1.1.1.1 -> int

SEC("lsm/socket_connect")
int BPF_PROG(restrict_connect, struct socket *sock, struct sockaddr *address, int addrlen, int ret)
{
    // Record the start time (in ns) for measuring this hook's execution.
    __u64 start_ns = bpf_ktime_get_ns();

    // Cast the address to an IPv4 socket address
    struct sockaddr_in *addr = (struct sockaddr_in *)address;
    __u32 dest = addr->sin_addr.s_addr;

    if (dest == blockme)
    {
        __u64 end_ns = bpf_ktime_get_ns();
        bpf_printk("lsm: blocking %d, exec time: %llu ns", dest, end_ns - start_ns);
        return -EPERM;
    }
    
    return 0;
}
