import java.util.*;

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
		return "arrayof_" + memberType.toString();
	}

	public Type getMemberType(){
		return memberType;
	}

	public int getLength(){
		return length;
	}

	public int getDimension(){
		int result = 1;
		for(Type iterator = memberType; iterator instanceof ArrayType; iterator = ((ArrayType)memberType).getMemberType())
			result++;
		return result;
	}

	public ArrayList<Integer> getDimensionsSize(){
		ArrayList<Integer> result;
		if(memberType instanceof ArrayType)
			result = ((ArrayType)memberType).getDimensionsSize();
		else
			result = new ArrayList<>();
		result.add(0, length);
		return result;
	}
}