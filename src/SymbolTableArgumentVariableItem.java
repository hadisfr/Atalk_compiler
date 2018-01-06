public class SymbolTableArgumentVariableItem extends SymbolTableVariableItemBase {
	
	public SymbolTableArgumentVariableItem(Variable variable, int offset) {
		super(variable, offset);
	}

	@Override
	public Register getBaseRegister() {
		return Register.AP;
	}

	@Override
	public boolean useMustBeComesAfterDef() {
		return false;
	}
}