public abstract class SymbolTableReceiverItem {

    public static final key_word = "recv_";

    private String name;
    private int size;

    public SymbolTableReceiverItem(String name){
        size = 0;
        this.name = name;

    }

    @Override
    public String getKey() {
        return key_word + name;
    }

    public int getSize(){
        return size;
    }

}