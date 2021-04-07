/*
 * entry.S - Entry point to system mode from user mode
 */

#include <asm.h>
#include <segment.h>
#include <errno.h>

/**************************************************/
/**** Save & Restore ******************************/
/**                                              **/
/** When we change to privilege level 0 (kernel) **/
/** (through an interrupt, a system call, an     **/
/** exception ...) we must save the state of the **/
/** currently running task (save).               **/
/**                                              **/
/** Stack layout in 'systemCall':                **/
/**                                              **/
/**   0(%esp) - %ebx    \                        **/
/**   4(%esp) - %ecx     |                       **/
/**   8(%esp) - %edx     |                       **/
/**   C(%esp) - %esi     | Register saved        **/
/**  10(%esp) - %edi     |  by 'save'            **/
/**  14(%esp) - %ebp     |                       **/
/**  18(%esp) - %eax     |                       **/
/**  1C(%esp) - %ds      |                       **/
/**  20(%esp) - %es      |                       **/
/**  24(%esp) - %fs      |                       **/
/**  28(%esp) - %gs     /                        **/
/**  2C(%esp) - %eip    \                        **/
/**  30(%esp) - %cs      |                       **/
/**  34(%esp) - %eflags  |  Return context saved **/
/**  38(%esp) - %oldesp  |   by the processor.   **/
/**  3C(%esp) - %oldss  /                        **/
/**                                              **/
/**************************************************/

#define SAVE_ALL \
      pushl %gs; \
      pushl %fs; \
      pushl %es; \
      pushl %ds; \
      pushl %eax; \
      pushl %ebp; \
      pushl %edi; \
      pushl %esi; \
      pushl %edx; \
      pushl %ecx; \
      pushl %ebx; \
      movl $__KERNEL_DS, %edx;    \
      movl %edx, %ds;           \
      movl %edx, %es;


#define RESTORE_ALL \
	popl %ebx; \
	popl %ecx; \
	popl %edx; \
	popl %esi; \
	popl %edi; \
	popl %ebp; \
	popl %eax; \
	popl %ds; \
	popl %es; \
	popl %fs; \
	popl %gs;

#define EOI \
	movb $0x20, %al ; \
	outb %al, $0x20 ;  


ENTRY(keyboard_handler)
	SAVE_ALL
	EOI
	call keyboard_routine
	RESTORE_ALL
	iret
	
ENTRY(clock_handler)
	SAVE_ALL
	EOI
	call clock_routine
	RESTORE_ALL
	iret
	
ENTRY(system_call_handler)	
	SAVE_ALL
	cmpl $0, %EAX
	jl err
	cmpl $MAX_SYSCALL, %EAX
	jg err
	call *sys_call_table(, %EAX, 0x04)
	jmp fin
err:
	movl $-ENOSYS, %EAX
fin:
	movl %EAX, 0x18(%ESP)
	RESTORE_ALL
	iret


ENTRY(syscall_handler_sysenter)
	push $__USER_DS
	push %EBP		// User stack address
	pushfl
	push $__USER_CS
	push 4(%EBP)       	// User return address
	SAVE_ALL
	cmpl $0, %EAX
	jl sysenter_err
	cmpl $MAX_SYSCALL, %EAX
	jg sysenter_err
	call *sys_call_table(, %EAX, 0x04) 
	jmp sysenter_fin
sysenter_err:
	movl $-ENOSYS, %EAX
sysenter_fin:
	movl %EAX, 0x18(%ESP)
	RESTORE_ALL
	movl (%ESP), %EDX	// Return address
	movl 12(%ESP), %ECX	// User stack address
	sti			// Enable interrupts again
	sysexit


ENTRY(writeMsr)
	push %ebp
	mov %esp, %ebp
	mov 8(%ebp), %ecx
	mov 12(%ebp), %eax
	mov $0, %edx
	wrmsr
	pop %ebp
	ret
	
ENTRY(task_switch)
	pushl %ebp
	movl %esp, %ebp
	pushl %esi
	pushl %edi
	pushl %ebx
	pushl 8(%ebp)
	call inner_task_switch
	addl $4, %esp
	popl %ebx
	popl %edi
	popl %esi
	popl %ebp
	ret
	
	
inner_task_switch:
	pushl %ebp
	movl %esp, %ebp

	movl 8(%ebp), %ebx //ebx <- @new
	
	movl %ebx, %esi //esi <- @new
	addl $4096, %esi //esi <- @new+4096  tss.esp0 <- (&new->stack[1024])
	leal tss, %edx 
	movl %esi, 4(%edx)

	
	pushl %esi
	pushl $0x175   //MSR0x175=esp
	call writeMsr
	addl $8, %esp

	
	pushl 4(%ebx) //pointer de dir_page //cr3 <- (&new->DIR)
	call set_cr3
	add $4, %esp

	
	mov %ebp, %ecx
	and $0xFFF000,%ecx   //current()->kernel_esp = ebp
	mov %ebp, 16(%ecx) //PID+dir_pages_baseAddr+list_head = 16

	
	mov 16(%ebx),%esp  //esp <- (new->kernel_esp)

	pop %ebp
	ret
	
/* void setMSR(unsigned long msr_number, unsigned long high, unsigned long low)*/
ENTRY(setMSR)
	push %ebp
	movl %esp, %ebp
	movl 0x10(%ebp), %eax
	movl 0xc(%ebp), %edx
	movl 0x8(%esp), %ecx
	wrmsr
	pop %ebp
	ret

/* void * get_ebp(void) */
ENTRY(get_ebp)
	mov %ebp, %eax
	ret

ENTRY(switch_stack)
	mov 4(%esp), %eax
	mov %ebp, (%eax)
	mov 8(%esp), %esp
	popl %ebp
	ret
