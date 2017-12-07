public class SymbolTableLocalVariableItem extends SymbolTableVariableItemBase {
	
	public SymbolTableLocalVariableItem(Variable variable, int offset) {
		super(variable, offset);
	}

	@Override
	public Register getBaseRegister() {
		return Register.TEMP9;
	}

	@Override
	public boolean useMustBeComesAfterDef() {
		return true;
	}
}