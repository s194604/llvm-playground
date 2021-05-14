; RUN: %test_no_runtime_execution

define i32 @main() {
entry:    
  %stack_var = alloca [2 x i32]
  %stack_var_1 = getelementptr [2 x i32], [2 x i32]* %stack_var, i32 0, i32 0
  store i32 15, i32* %stack_var_1
  %stack_var_2 = getelementptr [2 x i32], [2 x i32]* %stack_var, i32 0, i32 1
  store i32 16, i32* %stack_var_2
  
  %asm_result = call { i32, i32 } asm "
		lwc	$0	=	[$2]	
		lwc	$1	=	[$2 + 1]	
		nop
	", "=&r,=r,r"
	(i32* %stack_var_1)
	
  ; Extract results
  %result_1 = extractvalue { i32, i32 } %asm_result, 0
  %result_2 = extractvalue { i32, i32 } %asm_result, 1
  
  ; Check correctness
  %correct_1 = icmp eq i32 %result_1, 15
  %correct_2 = icmp eq i32 %result_2, 16
  %correct = and i1 %correct_1, %correct_2
  
  ; Negate result to ensure 0 is returned on success
  %result_0 = xor i1 %correct, 1 
  
  %result = zext i1 %result_0 to i32
  ret i32 %result
}