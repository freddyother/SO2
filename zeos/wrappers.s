# 1 "wrappers.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "wrappers.S"
# 1 "include/asm.h" 1
# 2 "wrappers.S" 2

.globl write; .type write, @function; .align 0; write:
    pushl %ebp
    mov %esp, %ebp
    pushl %ecx
    pushl %edx
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
    popl %edx
    popl %ecx
    popl %ebp
    ret
