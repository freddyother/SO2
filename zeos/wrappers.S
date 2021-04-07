#include <asm.h>

ENTRY(write)
    pushl %ebp
    mov %esp, %ebp
    pushl %ebx
    mov 8(%ebp), %ebx # fd
    mov 12(%ebp), %ecx # buffer
    mov 0X10(%ebp), %edx # size

    mov $0x04, %eax # access the 4th position in the sys_call_table

    pushl $write_return  
    pushl %ebp 
    mov %esp, %ebp 
    sysenter

write_return:
    cmpl $0x0, %eax
    jg write_continue
    neg %eax
    mov %eax, errno
    mov $-1, %eax

write_continue:
    popl %ebp
    add $0x4, %esp
    popl %ebx
    popl %ebp
    ret


ENTRY(gettime)
	pushl %ebp
	mov %esp, %ebp
	pushl %ebx
	mov $10, %eax
    pushl $gettime_return 
	pushl %ebp 
	mov %esp, %ebp 
	sysenter 

gettime_return:
	cmpl $0x0, %eax
	jg gettime_continue
	neg %eax
	mov %eax, errno
	mov $-1, %eax

gettime_continue:
	popl %ebp
    add $0x4, %esp
	popl %ebx
    popl %ebp
	ret
	
ENTRY(getpid)
     pushl %ebp
     mov %esp, %ebp
     pushl %ebx
     mov $20, %eax
     pushl $getpid_return 
    pushl %ebp 
    mov %esp, %ebp 
    sysenter

getpid_return:
     cmpl $0x0, %eax
     jg gettime_continue
     neg %eax
     mov %eax, errno
     mov $-1, %eax

getpid_continue:
    popl %ebp
    add $0x4, %esp
    popl %ebx
    popl %ebp
    ret
    

ENTRY(fork)
   pushl %ebp
   mov %esp, %ebp
   pushl %ebx
   mov $2, %eax
   pushl $fork_return 
    pushl %ebp 
    mov %esp, %ebp 
    sysenter

fork_return:
   cmpl $0x0, %eax
   jg gettime_continue
   neg %eax
   mov %eax, errno
   mov $-1, %eax

fork_continue:
   popl %ebp
   add $0x4, %esp
   popl %ebx
   popl %ebp
    ret
    
ENTRY(exit)
   pushl %ebp
   mov %esp, %ebp
   pushl %ebx
   mov $20, %eax
   	pushl $exit_return 
    pushl %ebp 
    mov %esp, %ebp 
    sysenter

exit_return:
   cmpl $0x0, %eax
   jg gettime_continue
   neg %eax
   mov %eax, errno
   mov $-1, %eax

exit_continue:
    popl %ebp
    add $0x4, %esp
   	popl %ebx
    popl %ebp
    ret

