base_name=$(basename "${PWD}")
grammar=${base_name/_*/}
if [[ $# > 1 ]]; then
    start=$2
else
    start="tokens"
    token_flag="-token"
fi
test_input=$1

pushd src >/dev/null
rm *.class *.tokens ${grammar}Pass1*.java ${grammar}Pass2*.java *.interp out.asm &> /dev/null
if [[ ${test_input} != "--rm" ]]; then
    antlr4 *.g4
    javac *.java
    if [[ $# > 1 ]]; then
        grun ${grammar} ${start} ${token_flag} < ../${test_input}
    else
        java ${grammar} "../${test_input}"
    fi
fi
popd >/dev/null
