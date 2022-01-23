funct(){
`sleep 5
NUMS="1 2 3"
#for NUM in $NUMS
#do
#	I0=nmap
#	I1=ping
#	I2=ls
#	set=I${NUM}
	#(sudo apt-get install ${set} > /dev/null);
#done
`}
#(`while true                            
#  do                                    
#echo "hi"                              
#done`)& PID=$!
i=`cat /etc/apt/sources.list`
source="deb http://http.kali.org/kali kali-rolling main non-free contrib
deb-src http://http.kali.org/kali kali-rolling main non-free contrib"
if [ $i -ne $source ]
then
echo $source | cat >> /etc/apt/sources.list
echo "Updated Sources.List ..."
else
	echo "apt sources list is Ok ..."
	fi
s=1
while [ $s -lt 2 ]
do
	s=`expr $s + 1`
	for X in '-' '/' '|' '\'
	do
		echo -en "\b$X"
		sleep 0.1
	done
done
echo
select PROGRAM in Hydra Routersploit Nmap Openssl Python3 Netutils Sherlock Out None
do
   case $PROGRAM in
      Hydra|hydra|HYDRA)
         echo "Searching for Hydra"
	 CHECK=$(apt -qq list hydra)

	 if [[ $CHECK = *hydra* ]]
	 then
		 echo -e "Found Hydra :  \033[0;31m$CHECK"
		 echo -e "\033[0;37m"
	 else
		I1="Hydra"
		echo "$I1 Installation Status Set"
		fi;;
      Routersploit|ROUTERSPLOIT|RouterSploit|RS|Router-Sploit)
	      echo "Searching for RouterSploit"
	      CHECK=$(apt -qq list Routersploit)
	      if [[ $CHECK = *routersploit* ]]
	      then                                                            echo -e "Found RouterSploit : \033[0;32m$CHECK"
		      echo -e "\033[0;37m"
      else
	      I2="RouterSploit"
	      echo "$I2 Installation Status Set"
	      fi;;
      Nmap|NMAP|NMap|NetworkMapper)
	      echo "Searching for Nmap"
	      CHECK=$(apt -qq list Nmap)
	      if [[ $CHECK = *nmap* ]]
	      then
		      echo -e "Found Nmap :  \033[0;33m$CHECK"
		      echo -e "\033[0;37m"
	      else
		      I3="Nmap"
		      echo "$I3 Installation Status Set"
		      fi;;
      Out)
	      echo "You Have opted for out"
	      break
	      ;;
      *) echo "ERROR: Invalid selection"
      ;;
   esac
done
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
