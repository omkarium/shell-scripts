printf '\n\tInternet speed test:  '

# http://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-working-indicator

spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"

# http://stackoverflow.com/questions/20165057/executing-bash-loop-while-command-is-running

speedtest > .st.txt &           ## & : continue running script
pid=$!                          ## PID of last command

# If this script is killed, kill 'speedtest':
trap "kill $pid 2> /dev/null" EXIT

# While 'speedtest' is running:
while kill -0 $pid 2> /dev/null; do
for i in "${spin[@]}"
do
    echo -ne "\b$i"
    sleep 0.1
done
done

# Disable the trap on a normal exit:
trap - EXIT

printf "\n\t           "
grep Download: .st.txt
printf "\t             "
grep Upload: .st.txt
echo ''
