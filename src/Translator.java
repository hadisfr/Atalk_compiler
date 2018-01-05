import java.util.*;
import java.io.*;

public class Translator {

    private File output;
    private ArrayList <String> instructions;
    private ArrayList <String> initInstructions;
    private int labelCounter;

    public Translator(){
        instructions = new ArrayList<String>();
        initInstructions = new ArrayList<String>();
        output = new File("../out.asm");
        try {
            output.createNewFile();
        } catch (Exception e){
            e.printStackTrace();
        }
        labelCounter = 0;
    }

    private String getLabel() {
        return "label" + (labelCounter++);
    }

    public void makeOutput(){
        this.addSystemCall(10);
        try {
            PrintWriter writer = new PrintWriter(output);
            writer.println("main:");
            writer.println("move $fp, $sp");
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
        instructions.add("li $a0, " + x);
        pushStack("a0");
        instructions.add("# end of adding a number to stack");
    }

    public void addToStack(String s, int adr){
        instructions.add("# start of adding local variable to stack");
        addToStack("fp", s, adr);
        instructions.add("# end of adding local variable to stack");
    }

    public void addGlobalToStack(String s, int adr){
        instructions.add("# start of adding global variable to stack");
        addToStack("gp", s, adr);
        instructions.add("# end of adding global variable to stack");
    }

    public void addAddressToStack(String s, int adr) {
        instructions.add("# start of local variable's adding address to stack");
        addAddressToStack("fp", s, adr);
        instructions.add("# end of adding local variable's address to stack");
    }

    public void addGlobalAddressToStack(String s, int adr){
        instructions.add("# start of adding global variable's address to stack");
        addAddressToStack("gp", s, adr);
        instructions.add("# end of adding global variable's address to stack");
    }

    private void addToStack(String ref, String s, int adr) {
        adr = adr * -1;
        instructions.add("lw $a0, " + adr + "($" + ref + ")");
        pushStack("a0");
    }

    private void addAddressToStack(String ref, String s, int adr) {
        adr = adr * -1;
        instructions.add("addiu $a0, $" + ref + ", " + adr);
        pushStack("a0");
    }

    public void addArrayToStack(int size) {
        instructions.add("# start of adding local array to stack");
        addArrayToStack("fp", size);
        instructions.add("# end of adding local array to stack");
    }

    public void addGlobalArrayToStack(int size) {
        instructions.add("# start of adding global array to stack");
        addArrayToStack("gp", size);
        instructions.add("# end of adding global array to stack");
    }

    public void addArrayAddressToStack() {
        instructions.add("# start of adding local array's address to stack");
        addArrayAddressToStack("fp");
        instructions.add("# end of adding local array's address to stack");
    }

    public void addGlobalArrayAddressToStack() {
        instructions.add("# start of adding global array's address to stack");
        addArrayAddressToStack("gp");
        instructions.add("# end of adding global array's address to stack");
    }

    private void addArrayToStack(String ref, int size) {
        addArrayAddressToStack(ref);
        instructions.add("lw $a1, 4($sp)");  // start addr
        popStack();
        for(int i = 0; i < size; i++) {
            instructions.add("lw $a0, " + (i * -4) + "($a1)");
            pushStack("a0");
        }
    }

    private void addArrayAddressToStack(String ref) {
        instructions.add("lw $a0, 4($sp)");  // array start addr
        popStack();
        instructions.add("lw $a1, 4($sp)");  // array length
        popStack();
        instructions.add("addi $a2, $zero, 4");
        instructions.add("mul $a1, $a1, $a2");
        instructions.add("neg $a1, $a1");
        instructions.add("add $a0, $a0, $a1");
        pushStack("a0");
    }

    public void popStack(){
        instructions.add("# start of pop stack");
        instructions.add("addiu $sp, $sp, 4");
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
        instructions.add("lw $a1, " + ((size + 1) * 4) + "($sp)");
        for(int i = 0; i < size; i++) {
            instructions.add("lw $a0, " + ((size - i) * 4) + "($sp)");
            instructions.add("sw $a0, " + -(i * 4) + "($a1)");
        }
        for(int i = 0; i < size; i++)
            popStack();  // data
        popStack();  // addr
        for(int i = 0; i < size; i++) {
            instructions.add("lw $a0, " + -(i * 4) + "($a1)");
            pushStack("a0");
        }
        instructions.add("# end of assign");
    }
    public void assignCommand() {
        assignCommand(1);
    }

    private void compareCommand(String cmd, String src_left, String src_right, String dst) {
        String label_middle = getLabel();
        String label_end = getLabel();
        instructions.add(cmd + " $" + src_left + ", $" + src_right  + ", " + label_middle);
        instructions.add("addi $" + dst + ", $zero, 0");
        instructions.add("j " + label_end);
        instructions.add(label_middle + ":\t" + "addi $" + dst + ", $zero, 1");
        instructions.add(label_end+":");
    }
    private void compareCommand(boolean is_equal, String temp_left, String temp_right, String dst, int size) {
        String label1 = getLabel();
        String label0 = getLabel();
        String label_end = getLabel();
        for(int i = 0; i < size; i++) {
            instructions.add("lw $" + temp_right + ", " + (size - i) * 4 + "($sp)");  // right operand
            instructions.add("lw $" + temp_left + ", " + (2 * size - i) * 4 + "($sp)");  // left operand
            instructions.add("bne, $" + temp_left + ", $" + temp_right + ", " + (is_equal ? label0 : label1));
        }
        instructions.add("j " + (is_equal ? label1 : label0));
        instructions.add(label0 + ":\t" + "addi $" + dst + ", $zero, 0");
        instructions.add("j " + label_end);
        instructions.add(label1 + ":\t" + "addi $" + dst + ", $zero, 1");
        instructions.add(label_end + ":");
        for(int i = 0; i < size * 2; i++)
            popStack();
    }

    public void unaryOperationCommand(String s){
        instructions.add("# start of unary operation " + s);
        instructions.add("lw $a0, 4($sp)");
        popStack();
        if (s.equals("-"))
            instructions.add("neg $a0");
        else if (s.equals("not")) {
            instructions.add("addi, $a1, $zero, 0");
            compareCommand("beq", "a1", "a0", "a0");
        }
        else
            instructions.add("# unary operation " + s + " did not handled.");
        pushStack("a0");
        instructions.add("# end of unary operation " + s);
    }

    public void binaryOperationCommand(String s){
        instructions.add("# start of binary operation " + s);
        instructions.add("lw $a0, 4($sp)");
        popStack();
        instructions.add("lw $a1, 4($sp)");
        popStack();
        if (s.equals("*"))
            instructions.add("mul $a0, $a0, $a1");
        else if (s.equals("/"))
            instructions.add("div $a0, $a1, $a0");
        else if (s.equals("+"))
            instructions.add("add $a0, $a0, $a1");
        else if (s.equals("-"))
            instructions.add("sub $a0, $a1, $a0");
        else if (s.equals("and"))
            instructions.add("and $a0, $a0, $a1");
        else if (s.equals("or"))
            instructions.add("or $a0, $a0, $a1");
        else if (s.equals("=="))
            compareCommand("beq", "a1", "a0", "a0");
        else if (s.equals("<>"))
            compareCommand("bne", "a1", "a0", "a0");
        else if (s.equals("<"))
            compareCommand("blt", "a1", "a0", "a0");
        else if (s.equals(">"))
            compareCommand("bgt", "a1", "a0", "a0");
        else
            instructions.add("# binary operation " + s + " did not handled.");
        pushStack("a0");
        instructions.add("# end of binary operation " + s);
    }

    public void binaryOperationCommand(String s, int size) {
        if(size == 1)
            binaryOperationCommand(s);
        else {
            instructions.add("# start of binary operation " + s);
            if (s.equals("=="))
                compareCommand(true, "a1", "a2", "a0", size);
            else if (s.equals("<>"))
                compareCommand(false, "a1", "a2", "a0", size);
            else
                instructions.add("# binary operation " + s + " did not handled.");
            pushStack("a0");
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
            instructions.add("lw $a0, " + ((size - i) * 4) + "($sp)");
            this.addSystemCall(syscall_number);
        }
        for(int i = 0; i < size; i++)
            popStack();
        instructions.add("addi $a0, $zero, 10");
        this.addSystemCall(11);
        instructions.add("# end of writing");
    }
    public void write(String type) {
        this.write(type, 1);
    }

    public void read() {
        this.addSystemCall(12);
        this.pushStack("v0");
    }

    public void pushStack(String src) {
        instructions.add("# start of push to stack");
        instructions.add("sw $" + src + ", 0($sp)");
        instructions.add("addiu $sp, $sp, -4");
        instructions.add("# end of push to stack");
    }
    
    public void addLocalVariable(int adr, int size, boolean initialized){
        adr = adr * -1;
        initInstructions.add("# start of adding a local variable");
        if(initialized != true) {
            initInstructions.add("li $a0, 0");
            for(int i = 0; i < size; i++)
                pushStack("a0");
        }
        initInstructions.add("# end of adding a local variable");
    }

    public void addGlobalVariable(int adr, int size){
        adr = adr * -1;
        initInstructions.add("# start of adding a global variable");
        initInstructions.add("li $a0, 0");
        for(int i = 0; i < size; i++)
            initInstructions.add("sw $a0, " + (adr - 4 * i) + "($gp)");
        initInstructions.add("# end of adding a global variable");
    }

    public void arrayLengthCalculate(int length) {
        instructions.add("# start of calculating array length");
        instructions.add("addi $a0, $zero, " + length);
        instructions.add("lw $a1, 4($sp)");
        popStack();
        instructions.add("mul $a0, $a0, $a1");
        instructions.add("lw $a1, 4($sp)");
        popStack();
        instructions.add("add $a0, $a0, $a1");
        pushStack("a0");
        instructions.add("# end of calculating array length");
    }
}
