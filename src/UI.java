public final class UI {
    static boolean hasError = false;
    static final boolean beautify = true;
    static enum OutputCategory {Actor, Receiver, LocalVar, GlobalVar, ArgumentVar}
    static enum VariableScopeState {GLOBAL, LOCAL, ARG}

    static void printError(String str){
        print((beautify ? red("Error") : "Error") + ": " + str);
        hasError = true;
    }

    static void print(String str){
        System.out.println(str);
    }

    static String red(String str) {
        return "\033[1;91m" + str + "\033[0;39m";
    }

    static String yellow(String str) {
        return "\033[1;93m" + str + "\033[0;39m";
    }

    static String blue(String str) {
        return "\033[1;96m" + str + "\033[0;39m";
    }

    static String green(String str) {
        return "\033[1;92m" + str + "\033[0;39m";
    }

    static String dark_blue(String str) {
        return "\033[1;94m" + str + "\033[0;39m";
    }

    static void printHeader(String det) {
        print(dark_blue("======================="));
        print("\t" + det);
        print(dark_blue("======================="));
    }

    static void printDetail(OutputCategory type, String det) {
        String beautyType = type.toString();
        if(beautify)
            switch(type) {
                case Actor:
                beautyType = blue(beautyType);
                break;
                case Receiver:
                beautyType = green(beautyType);
                break;
                case LocalVar:
                case GlobalVar:
                case ArgumentVar:
                beautyType = yellow(beautyType);
                break;
            }
        if(!hasError)
            print(beautyType + ":\t" + det);
    }
};