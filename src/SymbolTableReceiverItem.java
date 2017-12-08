import java.util.*;

public class SymbolTableReceiverItem extends SymbolTableItem {

    public static final String key_word = "recv_";

    private Receiver receiver;
    private int size;

    public SymbolTableReceiverItem(Receiver receiver){
        size = 0;
        this.receiver = receiver;
    }

    @Override
    public String getKey() {
        ArrayList<String> argTypes = receiver.getArgTypes();
        String argsKey = String.join("_", argTypes);
        return key_word + receiver.getName() + "_" + argsKey;
    }

    public int getSize(){
        return size;
    }

}