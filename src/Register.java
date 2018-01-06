public class Register {

	public static final Register ACC = new Register("$a0"); // Accumulator
	public static final Register ARGS_ADDR = new Register("$a1"); // Accumulator
	public static final Register SP = new Register("$sp"); // Stack Pointer
	public static final Register GP = new Register("$gp"); // Global Pointer
	public static final Register FP = new Register("$fp"); // Frame Pointer
	public static final Register TP = new Register("$s0"); // Args Tell Pointer
	public static final Register MP = new Register("$s1"); // Mailboxes' Pointer
	public static final Register AP = new Register("$s2"); // Args Recv Pointer
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
