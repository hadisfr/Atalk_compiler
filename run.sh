base_name=$(basename "${PWD}")
grammar=${base_name/_*/}
test_output="out.s"

if [[ $# == 0 ]]; then
    echo "usage:
        $0 <${grammar} file>                make '${test_output}' MIPS file
        $0 <${grammar} file> --tokens       tokenize file
        $0 <${grammar} file> --run          make '${test_output}' run it using SPIM
        $0 [<${grammar} file>] --rm         clean src directory
    "
    exit 0
fi

test_input=$1

pushd src >/dev/null
rm *.class *.tokens ${grammar}Pass1*.java ${grammar}Pass2*.java *.interp *.s &> /dev/null
if [[ $1 != "--rm" && $2 != "--rm" ]]; then
    if [[ $2 == "--tokens" ]]; then
        antlr4 ${grammar}Pass1.g4 && javac ${grammar}Pass1*.java && grun ${grammar}Pass1 tokens -tokens < ../${test_input}
    else
        antlr4 *.g4 && javac *.java && java ${grammar} "../${test_input}"
        if [[ $2 == "--run" ]]; then
            echo -e "\033[1;94m=======================\033[0;39m"
            echo -e "\t  RUN"
            echo -e "\033[1;94m=======================\033[0;39m"
            spim -f ../${test_output}
        fi
    fi
fi
popd >/dev/null
