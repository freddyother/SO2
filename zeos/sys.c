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

#include <system.h>

#define LECTURA 0
#define ESCRIPTURA 1
#define BUFFER_KER_SIZE 256

extern int zeos_ticks;

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

int global_PID=100;

int ret_from_fork()
{
  return 0;
}


int sys_fork()
{
  int PID=-1;

 if (list_empty(&freequeue)) return -ENOMEM;
 struct list_head *l = list_first(&freequeue);
 list_del(l);
 
 struct task_struct *tStruct_child = list_head_to_task_struct(l);
 struct task_struct *tStruct_parent = current();
 union task_union *tUnion_child = (union task_union *) tStruct_child;
 union task_union *tUnion_parent = (union task_union *) tStruct_parent;
	copy_data(tUnion_parent, tUnion_child, sizeof (union task_union));
 
 allocate_DIR(tStruct_child);  

 page_table_entry *pTable_child = get_PT(tStruct_child);
 page_table_entry *pTable_parent = get_PT(tStruct_parent);
 
 int frames[NUM_PAG_DATA];
	for (int i = 0; i < NUM_PAG_DATA; ++i) {
         frames[i] = alloc_frame();
         if (frames[i] == -1) {
                 for (int j = 0; j < i; ++j) {
                         free_frame(frames[j]);
                         del_ss_pag(pTable_child, PAG_LOG_INIT_DATA+j);
                 }
                 list_add(l, &freequeue);
                return -ENOMEM;
         } else {
                 set_ss_pag(pTable_child, PAG_LOG_INIT_DATA+i, frames[i]);
         }
 	}  
       
  for (int i = 0; i < NUM_PAG_KERNEL; i++) {
    set_ss_pag(pTable_child, i, get_frame(pTable_parent, i));
  }
  
  for (int i = 0; i < NUM_PAG_CODE; i++) {
    set_ss_pag(pTable_child, PAG_LOG_INIT_CODE+i, get_frame(pTable_parent, PAG_LOG_INIT_CODE+i));
  }

  for (int i = NUM_PAG_KERNEL+NUM_PAG_CODE; i < NUM_PAG_KERNEL+NUM_PAG_CODE+NUM_PAG_DATA; i++) {
    set_ss_pag(pTable_parent, i+NUM_PAG_DATA, get_frame(pTable_child, i));
    copy_data((void*)(i<<12), (void*)((i+NUM_PAG_DATA)<<12), PAGE_SIZE);
    del_ss_pag(pTable_parent, i+NUM_PAG_DATA);
  }

  set_cr3(get_DIR(tStruct_parent));
  tStruct_child->PID = ++global_PID;
  PID = tStruct_child->PID;

   tUnion_child->stack[KERNEL_STACK_SIZE - 1] = ret_from_fork;
   tUnion_child->stack[KERNEL_STACK_SIZE - 2] = 0;
   
   list_add_tail(&tStruct_child->list, &readyqueue);

  return PID;
}

void sys_exit()
{  
  page_table_entry *pTable_parent = get_PT(current());

  for (int i = 0; i < NUM_PAG_DATA; i++)   {
    free_frame(get_frame(pTable_parent, PAG_LOG_INIT_DATA+i));
    del_ss_pag(pTable_parent, PAG_LOG_INIT_DATA+i);
  }
  
  list_add_tail(&(current()->list), &freequeue);
  
  sched_next_rr();

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

int sys_gettime() {
	return zeos_ticks;
}
