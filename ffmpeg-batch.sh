#! /bin/bash

#Author: Omkaram Venkatesh
#July 17th 2023

mkdir -p src
mkdir -p dest

srcDir=$1
destDir=$2
okFiles=0
failedFiles=0
okFilesSize=0
failedFilesSize=0

trap printout SIGINT
printout() {
    echo ""
    echo "Exiting now..."
    exit
}

for filename in "$srcDir"/*; do

        basePath=${filename}
        baseName=${basePath##*/}
	if [ -f ${destDir}/${baseName} ]; then
    		echo "${destDir}/${baseName} ==> File already present! Skipping to next..."
    		continue
	fi

        ffmpeg -loglevel error -v quiet -stats -i "$filename" -c:v libx264 -b:v 6000k -threads 6 -c:a copy "$destDir"/"$baseName"
	echo "[size=$(du -sh ${destDir}/${baseName} | head -c4)] Compression complete ${filename} to ${destDir}/${baseName}"
done
echo -e "\nxxxxxxxxxxxx Video Duration Log xxxxxxxxxxxxxxx\n";
for filename in "$srcDir"/*; do

        basePath=${filename}
        baseName=${basePath##*/}
	in_filesize=$(stat --printf="%s" $filename)
	out_filesize=$(stat --printf="%s" ${destDir}/${baseName})
	in_length=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$filename") | grep -Eo "^[0-9]+.[0-9]{2}
        out_length=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$destDir"/"$baseName") | grep -Eo "^[0-9]+.[0-9]{2}
	if [[ "$in_length" == "$out_length" ]];
	then echo "[SUCCESS] The file length $filename is the same in both src ($in_filesize) and destination ($out_filesize)";
		((okFiles++));
	else
		echo "[FAILED] The file $filename is not the same.";
		((failedFiles++));
	fi
done
echo -e "\n+++++++++++++ Video File Size Log +++++++++++++\n";
for filename in "$srcDir"/*; do

        basePath=${filename}
        baseName=${basePath##*/}
        in_filesize=$(stat --printf="%s" $filename)
        out_filesize=$(stat --printf="%s" ${destDir}/${baseName})
        if [[ "$in_filesize" -gt "$out_filesize" ]];
        then
                ((okFilesSize++));
        else
                echo "[FAILED] The file $filename output ($out_filesize) is greater than the source ($in_filesize)";
                ((failedFilesSize++));
        fi

done


echo -e "\n=======Summary=======";
echo "Ok file count: $okFiles";
echo "Failed file count: $failedFiles";
echo "Files with src > dest file size count: $okFilesSize";
echo "Files with dest > src file size count: $failedFilesSize";
