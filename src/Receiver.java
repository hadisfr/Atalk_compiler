import java.util.*;

public class Receiver {

	private String name;
	private ArrayList<Variable> args;

	public Receiver(String name, ArrayList<Variable> args) {
		this.name = name;
		this.args = args;
	}

	public String getName(){
		return this.name;
	}

	@Override
	public String toString() {
		return getName();
	}

}