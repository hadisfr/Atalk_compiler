public class SymbolTableActorItem extends SymbolTableItem {

    public static final String key_word = "actor" + SymbolTableItem.delimiter;

    private Actor actor;
    private int offset;

    public SymbolTableActorItem(Actor actor, int offset){
        super();
        this.actor = actor;
        this.offset = offset;
    }

	@Override
	public String getKey() {
        return getKey(actor.getName());
    }
    
    public int getOffset() {
		return offset;
	}

    public static String getKey(String name) {
        return key_word + name;
    }

	public int getSize(){
	    return ((actor.getMailboxSize() * 2) + 1) * 4;
    }

    public int getMailboxSize(){
        return actor.getMailboxSize();
    }

}