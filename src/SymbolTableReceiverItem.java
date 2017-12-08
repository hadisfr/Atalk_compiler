import java.util.*;

public class SymbolTableReceiverItem extends SymbolTableItem {

    public static final String key_word = "recv" + SymbolTableItem.delimiter;

    private Receiver receiver;
    private int size;

    public SymbolTableReceiverItem(Receiver receiver){
        super();
        size = 0;
        this.receiver = receiver;
    }

    @Override
    public String getKey() {
        ArrayList<String> argTypes = receiver.getArgTypes();
        String argsKey = String.join(SymbolTableItem.delimiter, argTypes);
        return key_word + receiver.getName() + SymbolTableItem.delimiter + argsKey;
    }

    public int getSize(){
        return size;
    }

}