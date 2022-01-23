
funct(){
S=1
while [ $S -lt 1000 ]
do
	S=`expr $S + 1`

done
}


#(`while true                            
#  do                                    
#echo "hi"                              
#done`)& PID=$!   
(`funct`)& PID=$!
start=`date +%s`
echo "THIS MAY TAKE A WHILE, PLEASE BE P
ATIENT WHILE ______ IS RUNNING..."      
printf "["                              
# While process is running...           
while kill -0 $PID 2> /dev/null; do     
    printf  "*"                      
    sleep 1                             
done
end=`date +%s`
runtime=$((end-start))
printf "] done!"
echo "Time taken to complete : $runtime
