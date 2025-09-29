# Test Scenarios for Bash Script Commenting

This document outlines a series of test scenarios designed to verify the correctness and robustness of the automated Bash script commenting solution.

---

### Scenario 1: Script with No Functions

-   **Description**: A simple script containing only sequential commands without any function definitions.
-   **Input Script (`test_no_func.sh`)**:
    ```bash
    #!/bin/bash
    echo "Starting process..."
    # This is a comment
    ls -l /tmp
    echo "Process finished."
    ```
-   **Expected Output**:
    -   A file header should be generated for `output/test_no_func.sh`.
    -   The description should state that the script performs a sequence of shell commands, such as listing directory contents.
    -   The `Usage` section should indicate direct execution: `bash test_no_func.sh`.
    -   No function header blocks should be present in the output file.

---

### Scenario 2: Script with Multiple Functions

-   **Description**: A standard utility script containing several functions with varying numbers of arguments.
-   **Input Script (`test_multi_func.sh`)**:
    ```bash
    #!/bin/bash

    # Prints a greeting
    say_hello() {
      echo "Hello, World!"
    }

    # Greets a specific person
    greet_user() {
      local user_name=$1
      echo "Hello, $user_name"
    }
    ```
-   **Expected Output**:
    -   A file header should be generated.
    -   A function header should be present above `say_hello()`. It should state "Arguments: None".
    -   A function header should be present above `greet_user()`. It should correctly identify `$1` as the user's name.

---

### Scenario 3: Function with Optional Arguments and Defaults

-   **Description**: A function that uses the `${VAR:-default}` syntax to provide default values for optional arguments.
-   **Input Script (`test_optional_args.sh`)**:
    ```bash
    #!/bin/bash
    create_file() {
      local filename=${1:-"output.txt"}
      local content=${2:-"default content"}
      echo "$content" > "$filename"
    }
    ```
-   **Expected Output**:
    -   The function header for `create_file` should describe both arguments.
    -   The argument descriptions should explicitly mention that they are optional and state their default values (e.g., `$1 - (Optional) The filename. Defaults to "output.txt".`).
    -   The "Outputs" section should mention that the function creates a file.

---

### Scenario 4: Script Reading from Stdin

-   **Description**: A script or function that is designed to process input piped to it from standard input.
-   **Input Script (`test_stdin.sh`)**:
    ```bash
    #!/bin/bash
    process_lines() {
      while read -r line; do
        echo "Processed: $line"
      done
    }
    process_lines
    ```
-   **Expected Output**:
    -   The file header description should mention that the script processes data from standard input.
    -   The `Examples` section should include a pipe example, like `echo "my data" | bash test_stdin.sh`.
    -   The function header for `process_lines` should describe that it reads from stdin and what it outputs to stdout.

---

### Scenario 5: Script with `getopts` Argument Parsing

-   **Description**: A script intended for direct execution that uses `getopts` for command-line option parsing.
-   **Input Script (`test_getopts.sh`)**:
    ```bash
    #!/bin/bash
    while getopts "i:o:" opt; do
      case $opt in
        i) input_file="$OPTARG" ;;
        o) output_file="$OPTARG" ;;
      esac
    done
    echo "Input: $input_file, Output: $output_file"
    ```
-   **Expected Output**:
    -   The file header `Usage` section should be dynamically generated to reflect the command-line options, for example: `bash test_getopts.sh -i <input_file> -o <output_file>`.
    -   The `Examples` section should show a valid command-line invocation.

---

### Scenario 6: Function with Complex Behavior (Side Effects)

-   **Description**: A function that has side effects beyond returning a value or writing to stdout, such as creating environment variables or deleting files.
-   **Input Script (`test_side_effects.sh`)**:
    ```bash
    #!/bin/bash
    setup_env() {
      export MY_VAR="true"
      rm -f /tmp/old_file.lock
      return 0
    }
    ```
-   **Expected Output**:
    -   The "Outputs" section of the function header for `setup_env` must describe all side effects:
        -   "Exports the MY_VAR environment variable."
        -   "Deletes the file /tmp/old_file.lock if it exists."
        -   "Returns 0 on success."

---

### Scenario 7: Empty or Malformed Script

-   **Description**: An empty file or a file with syntax errors.
-   **Input Script (`test_empty.sh`)**:
    ```bash
    # This file is empty or contains invalid bash syntax
    ```
-   **Expected Output**:
    -   The process should not crash.
    -   It should either produce a minimally commented file (with a header noting the lack of content) or gracefully skip the file and log a warning. The preferred behavior is to generate a header with a description like "[This script is empty or could not be parsed.]".