
funct(){
`sleep 5
(ifconfig > /dev/null);`
}
#(`while true                            
#  do                                    
#echo "hi"                              
#done`)& PID=$!   
s=1
while [ $s -lt 5 ]
do
	s=`expr $s + 1`
	for X in '-' '/' '|' '\'
	do
		echo -en "\b$X"
		sleep 0.1
	done
done
echo
(`funct`)& PID=$!
start=`date +%s`
PID2=$PID
echo
echo
echo "  PERFORMING THE INSTALLATION, PLEASE BE PATIENT WHILE THE PROCESS IS RUNNING..."      
printf "["                              
# While process is running...           
while kill -0 $PID 2> /dev/null; do     
    printf  "*"                      
    sleep 1                             
done
end=`date +%s`
printf "]       done!\n"
runtime=$((end-start))
echo "The time taken to complete the process $PID2 : $runtime Seconds "
runtime=0
