/*
 * sys.c - Syscalls implementation
 */
#include <devices.h>

#include <utils.h>

#include <io.h>

#include <mm.h>

#include <mm_address.h>

#include <sched.h>

#include <errno.h>

#define LECTURA 0
#define ESCRIPTURA 1
#define BUFFER_KER_SIZE 256

int check_fd(int fd, int permissions)
{
  if (fd!=1) return -9; /*EBADF*/
  if (permissions!=ESCRIPTURA) return -13; /*EACCES*/
  return 0;
}

int sys_ni_syscall()
{
	return -38; /*ENOSYS*/
}

int sys_getpid()
{
	return current()->PID;
}

int sys_fork()
{
  int PID=-1;

  // creates the child process
  
  return PID;
}

void sys_exit()
{  
}

int sys_write(int fd, char *buffer, int size)
{
	/*fd: file descriptor. In this delivery it must always be 1.
	buffer: pointer to the bytes.
	size: number of bytes.
	return ’ Negative number in case of error (specifying the kind of error) and	
	the number of bytes written if OK.*/
	int ret;
	if ((ret= check_fd(fd, ESCRIPTURA)))return ret;
	if (buffer == NULL) return -EFAULT;
	if (size < 0) return -EINVAL;
	
	int num_bytes = size;
	char buff[BUFFER_KER_SIZE]; 
	
	while (num_bytes > BUFFER_KER_SIZE)
	{
		copy_from_user(buffer,buff,BUFFER_KER_SIZE);
		ret = sys_write_console(buff,BUFFER_KER_SIZE);
		buffer += ret;
		num_bytes -= ret;
	}
	if (num_bytes > 0)
	{
		copy_from_user(buffer,buff,num_bytes);
		ret = sys_write_console(buff,num_bytes);
		num_bytes -= ret;
	}
	
	return size-num_bytes;	
}
