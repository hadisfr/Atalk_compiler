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
rm *.class *.tokens ${grammar}*.java &> /dev/null
antlr4 ${grammar}.g4
javac *.java
grun ${grammar} ${start} ${token_flag} -gui < ../${test_input}
popd >/dev/null