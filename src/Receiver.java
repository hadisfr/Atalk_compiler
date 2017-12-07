import java.util.*;

import com.sun.org.apache.xpath.internal.operations.Variable;

public class Receiver {

	private String name;
	private ArrayList<Variable> args;

	public Receiver(String name, ArrayList<Variable> args) {
		this.name = name;
		this.args = args;
	}

	public ArrayList<String> getArgTypes(){
		ArrayList<String> result = new ArrayList<>();
		for(int i = 0; i < args.size(); i++){
			result.add(args.get(i).getType().toSrting());
		}
		return result;
	}

	public String getName(){
		return this.name;
	}

	@Override
	public String toString() {
		return getName();
	}

}