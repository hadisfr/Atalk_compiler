public class SymbolTableArgumentVariableItem extends SymbolTableVariableItemBase {
	
	public SymbolTableArgumentVariableItem(Variable variable, int offset) {
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