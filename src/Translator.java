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
        instructions.add("# adding a number to stack");
        instructions.add("li $a0, " + x);
        pushStack("a0");
        instructions.add("# end of adding a number to stack");
    }

    public void addToStack(String s, int adr){
        adr = adr * -1;
        instructions.add("# start of adding variable to stack");
        instructions.add("lw $a0, " + adr + "($fp)");
        pushStack("a0");
        instructions.add("# end of adding variable to stack");
    }

    public void addAddressToStack(String s, int adr) {
        adr = adr * -1;
        instructions.add("# start of adding address to stack");
        instructions.add("addiu $a0, $fp, " + adr);
        pushStack("a0");
        instructions.add("# end of adding address to stack");
    }

    public void addGlobalAddressToStack(String s, int adr){
        adr = adr * -1;
        instructions.add("# start of adding global address to stack");
        instructions.add("addiu $a0, $gp, " + adr);
        pushStack("a0");
        instructions.add("# end of adding global address to stack");
    }

    public void popStack(){
        instructions.add("# pop stack");
        instructions.add("addiu $sp, $sp, 4");
        instructions.add("# end of pop stack");
    }

    public void addSystemCall(int x){
        instructions.add("# start syscall " + x);
        instructions.add("li $v0, " + x);
        instructions.add("syscall");
        instructions.add("# end syscall");
    }

    public void assignCommand(){
        instructions.add("# start of assign");
        instructions.add("lw $a0, 4($sp)");
        popStack();
        instructions.add("lw $a1, 4($sp)");
        popStack();
        instructions.add("sw $a0, 0($a1)");
        pushStack("a0");
        instructions.add("# end of assign");
    }

    private void compareCommand(String cmd, String src_left, String src_right, String dst) {
        String label_middle = getLabel();
        String label_end = getLabel();
        instructions.add(cmd + " $" + src_left + ", $" + src_right  + ", "+ label_middle);
        instructions.add("addi $" + dst + ", $zero, 0");
        instructions.add("j " + label_end);
        instructions.add(label_middle + ":\t" + "addi $" + dst + ", $zero, 1");
        instructions.add(label_end+":");
    }

    public void unaryOperationCommand(String s){
        instructions.add("# unary operation " + s);
        instructions.add("lw $a0, 4($sp)");
        popStack();
        if (s.equals("-"))
            instructions.add("neg $a0");
        else if (s.equals("not"))
            instructions.add("not $a0, $a0");
        else
            instructions.add("# unary operation " + s + " did not handled.");
        pushStack("a0");
        instructions.add("# end of unary operation " + s);
    }

    public void binaryOperationCommand(String s){
        instructions.add("# binary operation " + s);
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

    public void write(String type, int size) {
        final int invalid_syscall_number = -1;
        int syscall_number = (type == "int") ? 1 : (type == "char") ? 11 : invalid_syscall_number;
        if(syscall_number == invalid_syscall_number) {
            instructions.add("# unsupported writing type");
            return;
        }
        instructions.add("# writing");
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
        write(type, 1);
    }

    public void pushStack(String src) {
        instructions.add("sw $" + src + ", 0($sp)");
        instructions.add("addiu $sp, $sp, -4");
    }
    
    public void addLocalVariable(int adr, int size, boolean initialized){
        adr = adr * -1;
        initInstructions.add("# adding a local variable");
        if(initialized != true) {
            initInstructions.add("li $a0, 0");
            for(int i = 0; i < size; i++)
                pushStack("a0");
        }
        initInstructions.add("# end of adding a local variable");
    }

    public void addGlobalToStack(int adr){
        adr = adr * -1;
        instructions.add("# start of adding global variable to stack");
        instructions.add("lw $a0, " + adr + "($gp)");
        pushStack("a0");
        instructions.add("# end of adding global variable to stack");
    }

    public void addGlobalVariable(int adr, int size){
        adr = adr * -1;
        initInstructions.add("# adding a global variable");
        initInstructions.add("li $a0, 0");
        for(int i = 0; i < size; i++)
            initInstructions.add("sw $a0, " + (adr + 4 * i) + "($gp)");
        initInstructions.add("# end of adding a global variable");
    }
}
