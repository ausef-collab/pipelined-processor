Group: Amr Usef and Omar Jah
Project: 3 ECE 200


Implementation:
In the forwarding stage we tracked the data dependency. We did this by tracking the data dependency between RD and RS in registers EXEMEM and MEMWB and stage EXE.
For the branching we tracked the data dependency between RD and RS or/and RT in register EXEMEM and ID.
Using the Forwarding controls from the Forwarding stage we determined what Operand needs to become in the EXE stage.
In the ID stage specifically in Compavre.v  we forward data from ALUResult to the determined Operand.
We also initiated a stall in IF/ID whenever a branch or jump is recorded.
And we detected and flushed whenever a Load use hazard was detected, this was done in the Hazard.v stage.
Distribution of Workload: We worked on the project together most of the time through zoom meeting and using Github. Amr did most of the implementation when it came to coding in verilog but the thinking behind how to solve the problems at hand we did together. 

Test benches:
This was the most frustrating part of our project. This is because we believe that at least our tier 1 test should have been passed. But there was an error that we did not understand and could not overcome. We went to the TA office hours to resolve this issue but most of the TA’s did not understand this error either. Also, we deleted the whole program and started over by implementing the code part by part and compiling it, however our initial issue did not change and the compiler gave us the same error. And because of this error or bug we could not pass any test benches because our code could not compile. We do believe that we had the right implementations in our code if you go through it.

Error and Bugs:
The error message was saying “lvalue required as left operand of assignment”. This is the error message we got and we tried many different ways we could think of to fix this problem but did not come up with a solution. And because of this our code could not compile. When the TA will try to compile the project they will see an error with MIPS.v pins, that is not the major issue the major issue is captured in the screenshot.
(a screenshot of error message will be attached to submission)

