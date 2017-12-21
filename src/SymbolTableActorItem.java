public class SymbolTableActorItem extends SymbolTableItem {

    public static final String key_word = "actor" + SymbolTableItem.delimiter;

    private Actor actor;
    private int size;

    public SymbolTableActorItem(Actor actor){
        super();
        size = 0;
        this.actor = actor;
    }

	@Override
	public String getKey() {
        return getKey(actor.getName());
	}

    public static String getKey(String name) {
        return key_word + name;
    }

	public int getSize(){
	    return size;
    }

    public void setSize(int size){

    }

}