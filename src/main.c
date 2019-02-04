#include <sys/wait.h>   // waitpid
#include <sys/mount.h>  // mount
#include <fcntl.h>      // open
#include <unistd.h>     // execv, sethostname, chroot, fchdir
#include <linux/sched.h> /* or #include <sched.h> */
#include <signal.h>
#include <string.h>
#include <stdio.h>


char *container_dir = "../busybox_root";
char *container_hostname = "a-simple-container";
int container_stack_size = 1 << 20; // 1024 * 1024
char *container_ip = "127.0.0.2";
char *container_bridge_name = "br0";
char *container_bridge_ip = "127.0.0.1";

int container_process(){
    printf("Launch container\n");

    int status_code;

    // 切换cwd到某个目录下
    status_code = chdir(container_dir);
    if(status_code<0){
        printf("chdir err, status_code=%d\n", status_code);
        return status_code;
    }

    // 直接使用当前目录作为根目录
    status_code = chroot(".");
    if(status_code<0){
        printf("chroot err, status_code=%d\n", status_code);
        return status_code;
    }

    // 设置容器主机名
    status_code = sethostname(container_hostname, strlen(container_hostname));
    if(status_code<0){
        printf("sethostname err, status_code=%d\n", status_code);
        return status_code;
    }

    // 设置独立的进程空间，挂载 proc 文件系统
    mount("none", "/proc", "proc", 0, NULL);
    mount("none", "/sys", "sysfs", 0, NULL);

    // 启动 shell
    char * const cmd[] = {"/bin/sh", NULL};
    status_code = execv(cmd[0], cmd);

    umount2("/proc", MNT_FORCE);
    umount2("/sys", MNT_FORCE);

    return status_code;
}

int main(int argc, char** argv) {
    int status_code;

    // 子进程栈
    char child_stack[container_stack_size];
    int child_pid = clone(&container_process, child_stack+container_stack_size, // 移动到栈底
                        // 使用新的 namespace 后，执行需要 sudo 权限
                        CLONE_NEWNS|        // new Mount 设置单独的文件系统
                        CLONE_NEWNET|    // new Net namespace
                        CLONE_NEWUTS|       // new UTS namespace hostname
                        CLONE_NEWPID|       // new PID namaspace，表现为：在容器里使用 ps 会只看到容器进程（祖先）的子孙进程，且进程id数值较小
                        SIGCHLD);           // 子进程退出时会发出信号给父进程

    if(child_pid < 0){
        printf("clone err, child_pid=%d\n", child_pid);
        return -1;
    }
                        
    waitpid(child_pid, &status_code, 0); // 等待子进程的退出

    return status_code;
}
