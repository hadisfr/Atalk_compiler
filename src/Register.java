public class Register {

	public static final Register ACC = new Register("$a0"); // Accumulator
	public static final Register SP = new Register("$sp"); // Stack Pointer
	public static final Register GP = new Register("$gp"); // Global Pointer
	public static final Register FP = new Register("$fp"); // Frame Pointer
	public static final Register TEMP0 = new Register("$t0");
	public static final Register TEMP1 = new Register("$t1");
	public static final Register TEMP2 = new Register("$t2");
	public static final Register TEMP3 = new Register("$t3");
	public static final Register TEMP4 = new Register("$t4");
	public static final Register TEMP5 = new Register("$t5");
	public static final Register TEMP6 = new Register("$t6");
	public static final Register TP = new Register("$t7"); // Args Tell Pointer
	public static final Register MP = new Register("$t8"); // Mailboxes' Pointer
	public static final Register AP = new Register("$t9"); // Args Recv Pointer
	public static final Register SYS_REG = new Register("$v0");
	public static final Register ZERO = new Register("$zero");

	public Register(String registerName) {
		this.registerName = registerName;
	}
	
	@Override
	public int hashCode() {
		return registerName.hashCode();
	}

	@Override
	public String toString() {
		return registerName;
	}

	protected String registerName;	
}
