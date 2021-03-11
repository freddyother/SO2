/* suma.S this file contains functions to add two numbers in assembly */
/*Creators :		Laia Batlle Ginesta */
/*			Fredy gallegos Cruz */

#include <asm.h>

ENTRY(addASM)
	push   %ebp 
        mov    %esp,%ebp 
        mov    0x8(%ebp),%edx 
        mov    0xc(%ebp),%eax 
        add    %edx,%eax 
        pop    %ebp 
        ret
