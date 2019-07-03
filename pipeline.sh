#!/usr/bin/env bash

##### AUT-pipeline v3
##### This script runs the tests module-wise, it is run if the "Module-flag" is set to true in autout.yml

# Runs GeneralPatterns
# Inputs: Source directory, Output directory, Index of module in autout.yml
run_gp() {
    SOURCE=$1
    OUTPUT=$2
    INDEX=$3

    pattern_file="GPA/pattern_${INDEX}"
    FLAG=`grep -c  "OpenPojo" ${pattern_file}`
    declare -a PROFILE
    if [[ ${FLAG} -eq 1 ]]; then
        PROFILE[${#PROFILE[@]}]="open-pojo"
    fi

    F1=`grep -c "Singleton" ${pattern_file}`
    F2=`grep -c "StaticFactory" ${pattern_file}`
    F3=`grep -c "Spring" ${pattern_file}`
    F4=`grep -c "Delegation" ${pattern_file}`
    if [[ ${F1} -eq 1  || ${F2} -eq 1  || ${F3} -eq 1  || ${F4} -eq 1  ]]; then
        PROFILE[${#PROFILE[@]}]="manual"
    fi

    for profile in "${PROFILE[@]}"
    do
        java -jar general-patterns-1.3.1.jar --project.src=${SOURCE}/src/main --project.out=${OUTPUT} --spring.profiles.active=${profile}
    done
}

# Runs GeneralPatternsAnalyzer
# Inputs: Source directory, Output directory
run_gpa() {
    SOURCE=$1
    OUTPUT=$2

    java -jar general-patterns-analyzer-1.3.2.jar --src=${SOURCE} --out=GPA/${OUTPUT} --auto=true
}

# Runs any custom supplied jar
# Name of jar is custom.jar
# Inputs for the jar are the command to run it, and optionally the source and output directories ${SOURCE}, ${OUTPUT}
run_custom() {
    COMMAND=$1
    SOURCE=$2
    OUTPUT=$3

    echo -e "\n\n${COMMAND}\n\n"
    ${COMMAND}
}

# Removes Generated tests from GeneralPatternsAnalyzer reports
clean_CSV() {
    (sed '/test-gen/d' GPA/${GPA_OUT}) > temp.csv
    mv temp.csv GPA/${GPA_OUT}
}

# Reads setup.yml and loads all the build, run and test commands into arrays
process_setup() {
    FLAG=0
    input_file="setup.yml"
    while read -r line
    do

      if [[ -z "$line" ]]; then
            continue
      fi

      if [[ "$line" == "build:" ]]; then
            FLAG=1
            continue
      elif [[ "$line" == "run:" ]]; then
            FLAG=2
            continue
      elif [[ "$line" == "test:" ]]; then
            FLAG=3
            continue
      fi

      if [[ ${FLAG} == 1 ]]; then
            BUILD[${#BUILD[@]}]="${line:2}"
      elif [[ ${FLAG} == 2 ]]; then
            RUN[${#RUN[@]}]="${line:2}"
      elif [[ ${FLAG} == 3 ]]; then
            TEST[${#TEST[@]}]="${line:2}"
       fi

    done < "$input_file"

}

# Runs all the project build commands
start_build() {
    for command in "${BUILD[@]}"
    do
        ${command}
    done
}

# Runs all the project run commands
start_run() {
    for command in "${RUN[@]}"
    do
        ${command}
    done
}

# Runs all the project run-test commands
start_test() {
    for command in "${TEST[@]}"
    do
        echo "${command}"
        ${command}
    done

    cp ./target/jacoco.exec ./AUT-reports/jacoco.exec
}

# Reads autout.yml and loads the specified patterns for each module into appropriately indexed files in GPA directory
process_patterns() {
    input_file="autout.yml"
    index=-1

    while read -r line
    do

        num=`echo ${line} | wc -m`
        if [[ ${num} -eq 0 ]]; then
            continue
        fi

        if [[ "${line}" == "-" ]]; then
            index=`expr ${index} + 1`
             continue
        fi

        if [[ ${line} == *"mainSourcePath: "*  || ${line} == *"generatedSourcePath: "* || ${line} == *"patternsToApply:"* ]]; then
            continue
        fi

        if [[ ${index} -gt -1 ]]; then
            echo ${line:2} >> GPA/pattern_${index}
        fi

    done < "$input_file"
}

# Generate HTML, CSV and XML JaCoCo reports from the binary executable that is made on running tests
# Inputs: FLAG to specify if generated reports should be moved to AUT-reports directory.
#     This is "0" for the initial testing phase, and "1" for the final phase whose reports are to be stored in AUT-reports
make_jacoco_report() {
    FLAG=$1

    if ((${FLAG} == "1")); then
        echo "delete and merge"
        java -jar jacococli.jar merge ./AUT-reports/jacoco.exec ./AUT-reports/s_jacoco.exec --destfile ./target/jacoco.exec
        rm ./AUT-reports/jacoco.exec ./AUT-reports/s_jacoco.exec ./jacococli.jar
    fi
    echo -e "\n\n***** Generating jacoco report\n\n"
    mvn jacoco:report

    if ((${FLAG} == "1")); then
        echo -e "\n\n***** Moving JaCoCo reports to AUT-reports directory\n\n"
        cp -r ./target/site/jacoco/ ./AUT-reports/jacoco/
    fi
}

# Generate Mutation Coverage reports using PITest
make_pitest_report() {
    echo -e "\n\n***** Generating Mutation Coverage report using PITest\n\n"
    mvn --fail-never org.pitest:pitest-maven:mutationCoverage
}

# Run clean-up script to remove tests that fail or raise errors
clean_up() {
    BEFORE=$1
    cd -
    find | grep ".*TEST-.*.xml" > reports
    junit_file="reports"
    while read -r file
    do
        ./gp-clean-up-bash.sh ${file} ${BEFORE}/src/test-gen/java
    done < "$junit_file"
    rm reports
    cd ${BEFORE}
}

run_auto_test() {

    mv src/test src/old_test
    mvn clean package -P autout-tests
    mv src/old_test src/test
    mv jacoco.exec s_jacoco.exec
    mv ./s_jacoco.exec ./AUT-reports/s_jacoco.exec
}

##### Start of Execution Flow #####
###################################

# GPA directory holds the indexed pattern files that tell GeneralPatterns what profiles to run,
#     as well as similarly indexed GeneralPatternsAnalyzer reports
mkdir GPA

# Declare the arrays that hold the project build, run, run-tests and run-custom-jar commands
declare -a BUILD
declare -a RUN
declare -a TEST

process_setup

# Read the source and output paths to all the modules into "src" and "out" files
awk '/mainSourcePath:/ {print $2}' autout.yml > src
awk '/generatedSourcePath:/ {print $2}' autout.yml > out

# Read custom jar command from autout.yml
CUSTOM_JAR_COMMAND=$(awk '/Custom-jar-command: / {$1=""; print $0 }' autout.yml) # Command to run custom jar

process_patterns

start_build

# Load source and output paths to the modules in arrays from "src" and "out" files
readarray SRC < src
readarray OUT < out

i=0 # Variable i is index for the modules as defined in autout.yml
while [[ ${i} -lt ${#SRC[@]} ]] # Loop over all the modules
do
    SRC[$i]=$(echo ${SRC[$i]}|tr -d '\n') # Remove trailing '\n' characters from source paths

    echo -e "\n\n***** Starting pipeline for module $[${i}+1]: ${SRC[$i]}..."

    cp jacococli.jar ${SRC[$i]}

    cd ${SRC[$i]}

    rm -r AUT-reports
    mkdir -p AUT-reports/pitest

    echo -e "\n\n***** Initial testing phase\n\n"
    start_test # Run the test commands inside the module

    make_jacoco_report "0"

    cd - # Move back to root directory

    echo -e "\n\n***** Running GeneralPatternsAnalyzer\n\n"
    GPA_OUT="analysis_$i.csv" # Output file for GeneralPatternsAnalyzer
    run_gpa ${SRC[$i]} ${GPA_OUT}

    clean_CSV

    input_file="./GPA/$GPA_OUT"
    line_no="0"
    GP_THRESHOLD=50 # Threshold of initial line coverage percentage below which we will run GeneralPatterns
    init_cov=0 # Initial Coverage - this is read from the GeneralPatternsAnalyzer CSV report

    while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 # Read the CSV input file (GeneralPatternsAnalyzer report)
    do
        if (($line_no > "0")); then
            cov=$[$[${f4}*100]/${f2}] # Initial Line Coverage in Percent
            init_cov=${f4}

            if (($cov < $GP_THRESHOLD)); then
                echo -e "\n\n***** For module $f1: Initial coverage is $cov% - Running GeneralPatterns\n\n"
                run_gp ${SRC[$i]} ${OUT[$i]} ${i}
            else
                echo -e "\n\n***** For module $f1: Initial coverage is $cov% - Not running GeneralPatterns - Initial coverage too high\n\n"
            fi

            if [[ -z ${CUSTOM_JAR_COMMAND} ]]; then # Check if an argument was passed while triggering this script (Command to run custom jar)
                echo -e "\n\n***** No Custom Jar command supplied, skipping this step...\n\n"
            else
                # If a custom jar is supplied while submitting the job, it will also be run
                if [[ -n $(find . -name "custom.jar") ]]; then # Find custom jar in directory
                    echo -e "\n\n***** For module $f1: Initial coverage is $cov% - Running custom supplied jar\n\n"
                    run_custom "${CUSTOM_JAR_COMMAND}" ${SRC[$i]} ${OUT[$i]}
                else
                    echo -e "\n\n***** ERROR: Custom Jar command supplied but no custom.jar found. Skipping...\n\n"
                fi
            fi
        fi

        line_no=$[$line_no+1]
    done < "$input_file"

    cd ${SRC[$i]}

    # If a test with the same name as a generated test already exists in the src/test directory, remove the new generated test
    find src/test-gen/ -type f -follow > files # Loads the names of all the generated tests into "files"
    file_list="files"
    while read -r filename
        do
            name=$(basename ${filename})
            find src/test -name ${name} -exec rm ${filename} \; # If test with same name is found, the generated test is deleted
        done < "$file_list"
    rm files

    echo -e "\n\n***** Running tests to check if any fail\n\n"
    run_auto_test

    # How many times to repeatedly clean up tests, then run again to see if any fail
    # Removing failing tests may cause a previously successful test to start failing
    RUN_CLEANUP_TIMES=2

    while [[ ${RUN_CLEANUP_TIMES} > 0 ]]
    do
        echo -e "\n\n***** Performing Clean-up\n\n"
        clean_up ${SRC[$i]}

        echo -e "\n\n***** Final testing phase\n\n"
        run_auto_test

        RUN_CLEANUP_TIMES=`expr ${RUN_CLEANUP_TIMES} - 1`
    done

    make_jacoco_report "1"

    cd - # Move back to root directory

    echo -e "\n\n***** Running GeneralPatternsAnalyzer to calculate LOC coverage gained\n\n"
    run_gpa ${SRC[$i]} ${GPA_OUT}

    clean_CSV

    line_no="0"
    while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 # Read the CSV input file (GeneralPatternsAnalyzer report)
    do
        if (($line_no > "0")); then
            cov_gain=$[${f4} - ${init_cov}] # Find coverage gained after generating the tests
            echo -e "\n\n***** LOC coverage gained for module $[${i}+1]: ${SRC[$i]} = ${cov_gain} Lines"
            echo -e "Initial coverage was ${init_cov} Lines, final is ${f4} Lines\n\n"
        fi

        line_no=$[$line_no+1]
    done < "$input_file"

    echo -e "\n\n***** Finished processing for module $[${i}+1]: ${SRC[$i]}..."

    i=`expr ${i} + 1`
done

make_pitest_report

# Load source paths to the modules in a fresh array
readarray SRC2 < src

echo -e "\n\n***** Moving PITest reports to AUT-reports directory\n\n"
i=0 # Variable i is index for the modules as defined in autout.yml
while [[ ${i} -lt ${#SRC2[@]} ]] # Loop over all the modules to move PITest reports to AUT-reports directory
do
    cd ${SRC2[$i]}

    cp -r ./target/pit-reports/. ./AUT-reports/pitest/ # Move PITest reports to AUT-reports directory

    cd -

    i=`expr ${i} + 1`
done

echo -e "\n\n"

# Clean up temporary files
rm -rf GPA
rm src
rm out
