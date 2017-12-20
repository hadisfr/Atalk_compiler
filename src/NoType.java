public class NoType extends Type {
	
	@Override
	public int size() {
		return Type.WORD_BYTES;
	}

	@Override
	public boolean equals(Object other) {
		if(other instanceof NoType)
			return true;
		return false;
	}

	@Override
	public String toString() {
		return "notype";
	}

	private static NoType instance;

	public static NoType getInstance() {
		if(instance == null)
			return instance = new NoType();
		return instance;
	}
}