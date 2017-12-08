import java.util.Random;

public class RandomStringGen{
    
    private static final String alphabet = "0123456789ABCDE";
    private static final int N = alphabet.length();

    private String result;

    public RandomStringGen(){
        result = "";
    }

    public String generate(int size){
        Random r = new Random();

        if(size < 0)
            size = 0;
        
        for (int i = 0; i < size; i++) {
            result += alphabet.charAt(r.nextInt(N));
        }
        return result;
    }
}