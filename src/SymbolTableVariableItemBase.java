public abstract class SymbolTableVariableItemBase extends SymbolTableItem {

	public static final String key_word = "var" + SymbolTableItem.delimiter;

	public SymbolTableVariableItemBase(Variable variable, int offset) {
		super();
		this.variable = variable;
		this.offset = offset;
	}

	public int getSize() {
		return variable.size();
	}

	public int getOffset() {
		return offset;
	}

	public Variable getVariable() {
		return variable;
	}

	@Override
	public String getKey() {
		return getKey(variable.getName());
	}

	public static String getKey(String name) {
		return key_word + name;
	}

	public abstract Register getBaseRegister();

	int offset;
	Variable variable;
}