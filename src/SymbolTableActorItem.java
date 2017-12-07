public abstract class SymbolTableActorItem {

    public static final String key_word = "actor_";

    private Actor actor;
    private int size;

    public SymbolTableActorItem(Actor actor){
        size = 0;
        this.actor = actor;
    }

	@Override
	public String getKey() {
		return key_word + actor.getName();
	}

	public int getSize(){
	    return size;
    }

    public void setSize(int size){

    }

}