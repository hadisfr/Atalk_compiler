public class Actor {
	
	public Actor(String name, int mailboxSize) {
		this.name = name;
		this.mailboxSize = mailboxSize;
	}

	public String getName(){
	    return this.name;
    }

    public int getMailboxSize() {
        return this.mailboxSize;
    }

	@Override
	public String toString() {
		return getName() + "<" + getMailboxSize() + ">";
	}

	private String name;
	private int mailboxSize;
}