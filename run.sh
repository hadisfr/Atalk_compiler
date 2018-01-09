base_name=$(basename "${PWD}")
grammar=${base_name/_*/}

if [[ $# == 0 ]]; then
    echo "usage:
        $0 <${grammar} file>                make 'out.s' MIPS file
        $0 <${grammar} file> --tokens       tokenize file
        $0 [<${grammar} file>] --rm         clean src directory
    "
    exit 0
fi

test_input=$1

pushd src >/dev/null
rm *.class *.tokens ${grammar}Pass1*.java ${grammar}Pass2*.java *.interp *.s &> /dev/null
if [[ $1 != "--rm" && $2 != "--rm" ]]; then
    antlr4 *.g4
    javac *.java
    if [[ $2 == "--tokens" ]]; then
        grun ${grammar}Pass1 tokens -tokens < ../${test_input}
    else
        java ${grammar} "../${test_input}"
    fi
fi
popd >/dev/null
