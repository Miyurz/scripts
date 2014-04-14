#!/bin/bash

function tell_me_meaning_of_exit_code {

   exit_code=$1
   echo Parameter passed :  ${exit_code}

    echo "Exit code ${exit_code}"
    case "${exit_code}" in 
     
       1)
       echo "Catchall for general errors." ;; 

       2)
       echo "Misuse of shell builtins." ;;

       126)
       echo "Command invoked cannot be executed.Possibly a permission issue!";;

       127)
       echo "Command invoked not found.";;

       128)
       echo "Invalid argument to exit.Exit takes only integer args in the range 0-255.";;

       130)
       echo "Script terminated by Control-C.";;

       255)
       echo "Exit status out of range.";;

       *)
       echo "Unknown exit code ${exit_code}. I will investigate" ;;    

    esac

   echo All error codes picked up from here : http://www.tldp.org/LDP/abs/html/abs-guide.html#AEN23549

}

tell_me_meaning_of_exit_code $1
