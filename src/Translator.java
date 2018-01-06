import java.util.*;
import java.io.*;

public class Translator {

    private File output;
    private ArrayList <String> instructions;
    private ArrayList <String> initInstructions;
    private ArrayList <String> argsInitInstruction;
    private int labelCounter;
    public final String scheduler_label = "schd";
    public final String quit_label = "quit";

    public Translator(){
        instructions = new ArrayList<String>();
        initInstructions = new ArrayList<String>();
        argsInitInstruction = new ArrayList<String>();
        output = new File("../out.asm");
        try {
            output.createNewFile();
        } catch (Exception e){
            e.printStackTrace();
        }
        labelCounter = 0;

        initInstructions.add("main:");
        initInstructions.add("move " + Register.FP + ", " + Register.SP);
        // TODO: init other ref regs
    }

    public String getLabel() {
        return "label" + (labelCounter++);
    }

    public void makeOutput(){
        try {
            initInstructions.add("j " + scheduler_label);
            instructions.add(quit_label + ":");
            addSystemCall(10);

            PrintWriter writer = new PrintWriter(output);
            for (int i=0;i<initInstructions.size();i++){
                writer.println(initInstructions.get(i));
            }
            for (int i=0;i<instructions.size();i++){
                writer.println(instructions.get(i));
            }
            writer.close();
        } catch (Exception e) { e.printStackTrace(); }
    }

    public void addToStack(int x){
        instructions.add("# start of adding a number to stack");
        instructions.add("li $t0, " + x);
        pushStack(new Register("$t0"));
        instructions.add("# end of adding a number to stack");
    }

    public void addToStack(String s, int adr){
        instructions.add("# start of adding local variable to stack");
        addToStack(Register.FP, s, adr);
        instructions.add("# end of adding local variable to stack");
    }

    public void addGlobalToStack(String s, int adr){
        instructions.add("# start of adding global variable to stack");
        addToStack(Register.GP, s, adr);
        instructions.add("# end of adding global variable to stack");
    }

    public void addArgumentToStack(String s, int adr){
        instructions.add("# start of adding argument variable to stack");
        addToStack(Register.AP, s, adr);
        instructions.add("# end of adding argument variable to stack");
    }

    public void addAddressToStack(String s, int adr) {
        instructions.add("# start of local variable's adding address to stack");
        addAddressToStack(Register.FP, s, adr);
        instructions.add("# end of adding local variable's address to stack");
    }

    public void addGlobalAddressToStack(String s, int adr){
        instructions.add("# start of adding global variable's address to stack");
        addAddressToStack(Register.GP, s, adr);
        instructions.add("# end of adding global variable's address to stack");
    }

    public void addArgumentAddressToStack(String s, int adr){
        instructions.add("# start of adding argument variable's address to stack");
        addAddressToStack(Register.AP, s, adr);
        instructions.add("# end of adding argument variable's address to stack");
    }

    private void addToStack(Register ref, String s, int adr) {
        adr *= -1;
        instructions.add("lw $t0, " + adr + "(" + ref + ")");
        pushStack(new Register("$t0"));
    }

    private void addAddressToStack(Register ref, String s, int adr) {
        adr *= -1;
        instructions.add("addiu $t0, " + ref + ", " + adr);
        pushStack(new Register("$t0"));
    }

    public void addArrayToStack(int size) {
        instructions.add("# start of adding local array to stack");
        addArrayToStack(Register.FP, size);
        instructions.add("# end of adding local array to stack");
    }

    public void addGlobalArrayToStack(int size) {
        instructions.add("# start of adding global array to stack");
        addArrayToStack(Register.GP, size);
        instructions.add("# end of adding global array to stack");
    }

    public void addArgumentArrayToStack(int size) {
        instructions.add("# start of adding argument array to stack");
        addArrayToStack(Register.AP, size);
        instructions.add("# end of adding argument array to stack");
    }

    public void addArrayAddressToStack() {
        instructions.add("# start of adding local array's address to stack");
        addArrayAddressToStack(Register.FP);
        instructions.add("# end of adding local array's address to stack");
    }

    public void addGlobalArrayAddressToStack() {
        instructions.add("# start of adding global array's address to stack");
        addArrayAddressToStack(Register.GP);
        instructions.add("# end of adding global array's address to stack");
    }

    public void addArgumentArrayAddressToStack() {
        instructions.add("# start of adding argument array's address to stack");
        addArrayAddressToStack(Register.AP);
        instructions.add("# end of adding argument array's address to stack");
    }

    private void addArrayToStack(Register ref, int size) {
        addArrayAddressToStack(ref);
        instructions.add("lw $t1, 4(" + Register.SP + ")");  // start addr
        popStack();
        for(int i = 0; i < size; i++) {
            instructions.add("lw $t0, " + (i * -4) + "($t1)");
            pushStack(new Register("$t0"));
        }
    }

    private void addArrayAddressToStack(Register ref) {
        instructions.add("lw $t0, 4(" + Register.SP + ")");  // array start addr
        popStack();
        instructions.add("lw $t1, 4(" + Register.SP + ")");  // array length
        popStack();
        instructions.add("addi $t2, " + Register.ZERO + ", 4");
        instructions.add("mul $t1, $t1, $t2");
        instructions.add("neg $t1, $t1");
        instructions.add("add $t0, $t0, $t1");
        pushStack(new Register("$t0"));
    }

    public void popStack(){
        instructions.add("# start of pop stack");
        instructions.add("addiu " + Register.SP + ", " + Register.SP + ", 4");
        instructions.add("# end of pop stack");
    }

    public void addSystemCall(int x){
        instructions.add("# start syscall " + x);
        instructions.add("li $v0, " + x);
        instructions.add("syscall");
        instructions.add("# end syscall");
    }

    public void assignCommand(int size) {
        instructions.add("# start of assign");
        instructions.add("lw $t1, " + ((size + 1) * 4) + "(" + Register.SP + ")");
        for(int i = 0; i < size; i++) {
            instructions.add("lw $t0, " + ((size - i) * 4) + "(" + Register.SP + ")");
            instructions.add("sw $t0, " + -(i * 4) + "($t1)");
        }
        for(int i = 0; i < size; i++)
            popStack();  // data
        popStack();  // addr
        for(int i = 0; i < size; i++) {
            instructions.add("lw $t0, " + -(i * 4) + "($t1)");
            pushStack(new Register("$t0"));
        }
        instructions.add("# end of assign");
    }
    public void assignCommand() {
        assignCommand(1);
    }

    private void compareCommand(String cmd, Register src_left, Register src_right, Register dst) {
        String label_middle = getLabel();
        String label_end = getLabel();
        instructions.add(cmd + " " + src_left + ", " + src_right  + ", " + label_middle);
        instructions.add("addi " + dst + ", " + Register.ZERO + ", 0");
        instructions.add("j " + label_end);
        instructions.add(label_middle + ":");
        instructions.add("addi " + dst + ", " + Register.ZERO + ", 1");
        instructions.add(label_end+":");
    }
    private void compareCommand(boolean is_equal, Register temp_left, Register temp_right, Register dst, int size) {
        String label1 = getLabel();
        String label0 = getLabel();
        String label_end = getLabel();
        for(int i = 0; i < size; i++) {
            instructions.add("lw " + temp_right + ", " + (size - i) * 4 + "(" + Register.SP + ")");  // right operand
            instructions.add("lw " + temp_left + ", " + (2 * size - i) * 4 + "(" + Register.SP + ")");  // left operand
            instructions.add("bne, " + temp_left + ", " + temp_right + ", " + (is_equal ? label0 : label1));
        }
        instructions.add("j " + (is_equal ? label1 : label0));
        instructions.add(label0 + ":");
        instructions.add("addi " + dst + ", " + Register.ZERO + ", 0");
        instructions.add("j " + label_end);
        instructions.add(label1 + ":");
        instructions.add("addi " + dst + ", " + Register.ZERO + ", 1");
        instructions.add(label_end + ":");
        for(int i = 0; i < size * 2; i++)
            popStack();
    }

    public void unaryOperationCommand(String s){
        instructions.add("# start of unary operation " + s);
        instructions.add("lw $t0, 4(" + Register.SP + ")");
        popStack();
        if (s.equals("-"))
            instructions.add("neg $t0");
        else if (s.equals("not")) {
            instructions.add("addi, $t1, " + Register.ZERO + ", 0");
            compareCommand("beq", new Register("$t1"), new Register("$t0"), new Register("$t0"));
        }
        else
            instructions.add("# unary operation " + s + " did not handled.");
        pushStack(new Register("$t0"));
        instructions.add("# end of unary operation " + s);
    }

    public void binaryOperationCommand(String s){
        instructions.add("# start of binary operation " + s);
        instructions.add("lw $t0, 4(" + Register.SP + ")");
        popStack();
        instructions.add("lw $t1, 4(" + Register.SP + ")");
        popStack();
        if (s.equals("*"))
            instructions.add("mul $t0, $t0, $t1");
        else if (s.equals("/"))
            instructions.add("div $t0, $t1, $t0");
        else if (s.equals("+"))
            instructions.add("add $t0, $t0, $t1");
        else if (s.equals("-"))
            instructions.add("sub $t0, $t1, $t0");
        else if (s.equals("and"))
            instructions.add("and $t0, $t0, $t1");
        else if (s.equals("or"))
            instructions.add("or $t0, $t0, $t1");
        else if (s.equals("=="))
            compareCommand("beq", new Register("$t1"), new Register("$t0"), new Register("$t0"));
        else if (s.equals("<>"))
            compareCommand("bne", new Register("$t1"), new Register("$t0"), new Register("$t0"));
        else if (s.equals("<"))
            compareCommand("blt", new Register("$t1"), new Register("$t0"), new Register("$t0"));
        else if (s.equals(">"))
            compareCommand("bgt", new Register("$t1"), new Register("$t0"), new Register("$t0"));
        else
            instructions.add("# binary operation " + s + " did not handled.");
        pushStack(new Register("$t0"));
        instructions.add("# end of binary operation " + s);
    }

    public void binaryOperationCommand(String s, int size) {
        if(size == 1)
            binaryOperationCommand(s);
        else {
            instructions.add("# start of binary operation " + s);
            if (s.equals("=="))
                compareCommand(true, new Register("$t1"), new Register("$t2"), new Register("$t0"), size);
            else if (s.equals("<>"))
                compareCommand(false, new Register("$t1"), new Register("$t2"), new Register("$t0"), size);
            else
                instructions.add("# binary operation " + s + " did not handled.");
            pushStack(new Register("$t0"));
            instructions.add("# end of binary operation " + s);
        }
    }

    public void write(String type, int size) {
        final int invalid_syscall_number = -1;
        int syscall_number = (type == "int") ? 1 : (type == "char") ? 11 : invalid_syscall_number;
        if(syscall_number == invalid_syscall_number) {
            instructions.add("# unsupported writing type");
            return;
        }
        instructions.add("# start of writing");
        for(int i = 0; i < size; i++) {
            instructions.add("lw $a0, " + ((size - i) * 4) + "(" + Register.SP + ")");
            this.addSystemCall(syscall_number);
        }
        for(int i = 0; i < size; i++)
            popStack();
        instructions.add("addi $a0, " + Register.ZERO + ", 10");
        this.addSystemCall(11);
        instructions.add("# end of writing");
    }
    public void write(String type) {
        this.write(type, 1);
    }

    public void read() {
        this.addSystemCall(12);
        this.pushStack(Register.SYS_REG);
    }

    public void pushStack(Register src) {
        instructions.add("# start of push to stack");
        instructions.add("sw " + src + ", 0(" + Register.SP + ")");
        instructions.add("addiu " + Register.SP + ", " + Register.SP + ", -4");
        instructions.add("# end of push to stack");
    }
    
    public void addLocalVariable(int adr, int size, boolean initialized){
        adr *= -1;
        instructions.add("# start of adding a local variable");
        if(initialized != true) {
            instructions.add("li $t0, 0");
            for(int i = 0; i < size; i++)
                pushStack(new Register("$t0"));
        }
        instructions.add("# end of adding a local variable");
    }

    public void addGlobalVariable(int adr, int size){
        adr *= -1;
        initInstructions.add("# start of adding a global variable");
        initInstructions.add("li $t0, 0");
        for(int i = 0; i < size; i++)
            initInstructions.add("sw $t0, " + (adr - 4 * i) + "(" + Register.GP + ")");
        initInstructions.add("# end of adding a global variable");
    }

    public void addArgumentVariable(int adr, int size) {
        adr *= -1;
        argsInitInstruction.add("# start of adding a argument variable");
        for(int i = 0; i < size; i++) {
            // ARGS_ADDR should be set before call
            argsInitInstruction.add("lw $t0, " + (-4 * i) + "(" + Register.ARGS_ADDR + ")");
            argsInitInstruction.add("sw $t0, " + (adr - 4 * i) + "(" + Register.AP + ")");
        }
        argsInitInstruction.add("# end of adding a argument variable");
    }

    public void arrayLengthCalculate(int length) {
        instructions.add("# start of calculating array length");
        instructions.add("addi $t0, " + Register.ZERO + ", " + length);
        instructions.add("lw $t1, 4(" + Register.SP + ")");
        popStack();
        instructions.add("mul $t0, $t0, $t1");
        instructions.add("lw $t1, 4(" + Register.SP + ")");
        popStack();
        instructions.add("add $t0, $t0, $t1");
        pushStack(new Register("$t0"));
        instructions.add("# end of calculating array length");
    }

    public void addLabel(String label) {
        instructions.add(label + ":");
    }

    public void addComment(String comment) {
        instructions.add("# " + comment);
    }

    public void check_if_expr(String label) {
        instructions.add("lw $t0, 4(" + Register.SP + ")");
        popStack();
        instructions.add("beqz $t0, " + label);
    }

    public void jump(String label) {
        instructions.add("j " + label);
    }

    public void define_receiver(String label) {
        instructions.add("# start of recv definition");
        instructions.add(label + ":");
        instructions.add("li " + Register.RUN + ", 1");
        instructions.add("# end of recv definition");
        instructions.addAll(argsInitInstruction);
        argsInitInstruction = new ArrayList<String>();
    }

    public void define_actor(String label, int adr) {
        adr *= -1;

        initInstructions.add("# start of actor definition");
        initInstructions.add("sw $zero, " + adr + "(" + Register.MP + ")");  // number of msgs in mailbox
        initInstructions.add("# end of actor definition");

        instructions.add("# start of actor's turn");
        instructions.add(label + ":");
        instructions.add("lw $t0, " + adr + "(" + Register.MP + ")");  // number of msgs in mailbox
        instructions.add("beqz $t0, " + scheduler_label);  // empty mailbox
        instructions.add("sub $t1, $t0, 1");
        instructions.add("sw $t1, " + adr + "(" + Register.MP + ")");  // next number of msgs in mailbox
        instructions.add("add $t0, $t0, $t0");
        instructions.add("neg $t0 $t0");
        instructions.add("add $t0, $t0, " + Register.MP);
        instructions.add("lw " + Register.ARGS_ADDR + ", 0($t0)");  // start addr of args
        instructions.add("add $t0, $t0, 1");
        instructions.add("lw $t1, 0($t0)");  // addr of recv handler
        instructions.add("jr $t1");
        instructions.add("# end of actor's turn");
    }

    public void add_scheduler(ArrayList<String> actor_labels) {
        String jumper_label = getLabel();
        String new_round_label = getLabel();

        initInstructions.add("# start of scheduler initialization");
        initInstructions.add("li " + Register.RUN + ", 0");
        initInstructions.add("li " + Register.CNT + ", 0");
        initInstructions.add("# end of scheduler initialization");

        instructions.add("# start of scheduler");
        instructions.add(scheduler_label + ":");
        instructions.add("add " + Register.CNT + ", " + Register.CNT + ", 1");
        instructions.add("li $t0, " + actor_labels.size());
        instructions.add("bgt " + Register.CNT + ", $t0, " + new_round_label);
        instructions.add("la $t0, " + jumper_label);
        instructions.add("add #t0, $t0, " + Register.CNT);
        instructions.add("sub, $t0, $t0, 1");
        instructions.add("jr $t0");
        instructions.add(jumper_label + ":");
        for(int i = 0; i < actor_labels.size(); i++)
            instructions.add("j " + actor_labels.get(i));
        instructions.add(new_round_label + ":");
        instructions.add("beqz " + Register.RUN + ", " + quit_label);
        instructions.add("li " + Register.RUN + ", 0");
        instructions.add("li " + Register.CNT + ", 0");
        instructions.add("j " + scheduler_label);
        instructions.add("# end of scheduler");
    }

    public void quit() {
        instructions.add("j " + quit_label);
    }

    public void tell(int actor_adr, String receiver_label, int size) {
        instructions.add("# start of tell");
        // TODO: complete
        instructions.add("# end of tell");
    }
}
