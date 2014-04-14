#!/bin/bash

function tell_me_meaning_of_exit_code {

   exit_code=$1
   echo Parameter passed :  ${exit_code}

    echo "Exit code ${exit_code}"

    case "${exit_code}" in 
     
       1)
       echo "Catchall for general errors."
       ;; 

       2)
       echo "Misuse of shell builtins." 
       ;;

       126)
       echo "Command invoked cannot be executed.Possibly a permission issue!"
       ;;

       127)
       echo "Command invoked not found."
       ;;

       128)
       echo "Invalid argument to exit.Exit takes only integer args in the range 0-255."
       ;;

       #130)
       #echo "Script terminated by Control-C.";;

       255)
       echo "Exit status out of range."
       ;;

       *)
       if [ ${exit_code} -gt 128 ] && [ ${exit_code} -le 192 ] ; then
           echo "Exit code  is between 128 and 192."
           signal_code=$( expr $exit_code - 128 )
           echo SIGNAL CODE = ${signal_code}
       
             case ${signal_code} in 

#1) SIGHUP	 2) SIGINT	 3) SIGQUIT	 4) SIGILL	 5) SIGTRAP
#6) SIGABRT	 7) SIGBUS	 8) SIGFPE	 9) SIGKILL	10) SIGUSR1
#11) SIGSEGV	12) SIGUSR2	13) SIGPIPE	14) SIGALRM	15) SIGTERM
#16) SIGSTKFLT	17) SIGCHLD	18) SIGCONT	19) SIGSTOP	20) SIGTSTP
#21) SIGTTIN	22) SIGTTOU	23) SIGURG	24) SIGXCPU	25) SIGXFSZ
#26) SIGVTALRM	27) SIGPROF	28) SIGWINCH	29) SIGIO	30) SIGPWR
#31) SIGSYS	34) SIGRTMIN	


                  
                  1)
                  echo "SIGHUP"
                  ;;
 
                  2)
                  echo "SIGINT"
                  ;;

                  3)
                  echo "SIGQUIT"
                  ;;

                  4)
                  echo "SIGILL"
                  ;;

                  5)
                  echo "SIGTRAP"
                  ;;

                  6)
                  echo "SIGABRT"
                  ;;

                  7)
                  echo "SIGBUS"
                  ;;
          esac

       else
           echo "Unknown exit code ${exit_code}. I will investigate"    
       fi
       ;;

    esac

   echo All error codes picked up from here : http://www.tldp.org/LDP/abs/html/abs-guide.html#AEN23549

}

tell_me_meaning_of_exit_code $1
