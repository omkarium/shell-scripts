#! /bin/bash

#Author: Omkaram Venkatesh
#July 17th 2023

srcDir=$1
destDir=$2
movedCount=0
unmovedCount=0
for filename in "$srcDir"/*; do

	basePath=${filename%.*}
	baseName=${basePath##*/}
	bitrate=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$filename")
	if [[ "$bitrate" -gt 9000000 ]]; 
   		then echo "The bitrate $bitrate is greater than 9k. Considering to move this file $filename to $destDir"; 
		mv $filename $destDir;
		((movedCount++));
	else
		echo "The file $filename bitrate $bitrate is less than 9k";
		((unmovedCount++));
	fi
done

echo -e "\n=======Summary=======";
echo "Total files noved: $movedCount";
echo "Total files not moved:$unmovedCount";


