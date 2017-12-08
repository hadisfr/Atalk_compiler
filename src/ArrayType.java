public class ArrayType extends Type {

	private int length;
	private Type memberType;

	public ArrayType(int length, Type memberType){
        this.length = length;
        this.memberType = memberType;
    }

	@Override
	public int size() {
		return memberType.size() * length;
	}

	@Override
	public boolean equals(Object other) {
		if(other instanceof ArrayType){
            if(((ArrayType) other).length == this.length)
			    return true;
        }
		return false;
	}

	@Override
	public String toString() {
		return "array_of_" + memberType.toString();
	}

	public Type getMemberType(){
		return memberType;
	}

}