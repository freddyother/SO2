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
