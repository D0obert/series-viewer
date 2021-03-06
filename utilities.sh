#!/bin/bash

#Commonly used utilities - utility functions are stored here

#Arguments
#$1 - Options:
#   -e - Escape ENTER prompt (Used when a prompt calls loopMain()
loopMain() {

    if [ "$1" != "-e" ]
    then
        read -p "
    Press ENTER to continue..."
    fi
    
    clear
    main

}

#Arguments:
#$1 - ans
#$2 - Y Result
#$3 - N Result
yesNo() {

    case "$1" in
            "Y" | "y" | "") "$2" ;;
            "N" | "n") "$3" ;;
            *) echo "$1 is not a valid input" && loopMain ;;
    esac

}

#Arguments:
#$1 - Option (Specifies which array needs to be updated)
#$2 - Attribute array
#$3 - Index to ignore
#$4 - New Value
updateAttribute() {

    tmp=()

    for (( i = 0; i <= $2; ))
    do
            if [ "$i" == "$3" ]
            then
                    tmp+=("$4")
            else
                    #=================[UPDATE ATTRIBUTE]=================#
                    case $1 in
                            "-p") tmp+=(${pathArray[$i]}) ;;
                            "-t") tmp+=(${titleArray[$i]}) ;;
                            "-c") tmp+=(${countArray[$i]}) ;;
                            "-ce") tmp+=(${currentEpArray[$i]}) ;;
                            "-s") tmp+=(${statusArray[$i]}) ;;
                            "-ts") tmp+=(${timeStampArray[$i]}) ;;
                            "-rt") tmp+=(${totalRuntimeArray[$i]}) ;;
                            "-crt") tmp+=(${currentRuntimeArray[$i]}) ;;
                    esac
            fi
            ((i+=1))
    done

}

#Obtain $epCount and $title
#Arguments:
#$1 - $path
parsePath() {

    totRunTime=0
    epArray=("empty")
    title="${1##*/}"
   
    #Increment $epCount and append current index to $epArray recursively
    for i in "$1"/*
    do
        ((epCount+=1))
        epArray+=("$i")
    done

    #Find the runtime (in seconds) of the entire file 
    for i in ${!epArray[@]}  
    do
        #Skip buffer object
        if [ "${epArray[$i]}" != "empty" ]
        then
                epLength="$(exiftool -S -n "${epArray[$i]}" | awk '/^Duration/ {print $2}' | paste -sd+ -| bc)"
                epLength=${epLength%\.*}
                ((totRunTime+=$epLength))
        fi
    done

}

#Override currEp
setcEp() {

    read -p "
    What episode do you want to start at?

    > " cEp

    updateAttribute -ce "$maxIndex" "$wOpt" "$cEp"
    currentEpArray=(${tmp[@]})

}

#Arguments:
#$1 - $currEp
#$2 - $epCount
#$3 - #status
updateProgBar() {
    
    max=$2
    curr=$1
    status=$3
    prog=$(bc <<<"scale=2;$curr/$max")
    perc=$(echo $prog | tr -d ".")

    if [ "$curr" == "0" -o "$status" == "Added" ]
    then
            progBar="░░░░░░░░░░ (0%)"
            longPBar="░░░░░░░░░░░░░░░░░░░░ ($perc%)"
            return
    fi

    if (( $(bc -l<<<"$prog<=0.10") )) 
    then
            progBar="▒░░░░░░░░░ ($perc%)"                   
            longPBar="▒▒░░░░░░░░░░░░░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.10") )) && (( $(bc -l<<<"$prog<0.20") )) 
    then
            progBar="▓▒░░░░░░░░ ($perc%)"    
            longPBar="▓▓▒▒░░░░░░░░░░░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.20") )) && (( $(bc -l<<<"$prog<0.30") )) 
    then
            progBar="▓▓▒░░░░░░░ ($perc%)"
            longPBar="▓▓▓▓▒▒░░░░░░░░░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.30") )) && (( $(bc -l<<<"$prog<0.40") )) 
    then
            progBar="▓▓▓▒░░░░░░ ($perc%)"
            longPBar="▓▓▓▓▓▓▒▒░░░░░░░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.40") )) && (( $(bc -l<<<"$prog<0.50") )) 
    then
            progBar="▓▓▓▓▒░░░░░ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.50") )) && (( $(bc -l<<<"$prog<0.60") )) 
    then
            progBar="▓▓▓▓▓▒░░░░ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.60") )) && (( $(bc -l<<<"$prog<0.70") )) 
    then
            progBar="▓▓▓▓▓▓▒░░░ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░ ($perc%)"
    elif (( $(bc -l<<<"$prog>=0.70") )) && (( $(bc -l<<<"$prog<0.80") )) 
    then
            progBar="▓▓▓▓▓▓▓▒░░ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░░"
    elif (( $(bc -l<<<"$prog>=0.80") )) && (( $(bc -l<<<"$prog<0.90") )) 
    then
            progBar="▓▓▓▓▓▓▓▓▒░ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░"
    elif (( $(bc -l<<<"$prog>=0.90") )) && (( $(bc -l<<<"$prog<1") )) 
    then
            progBar="▓▓▓▓▓▓▓▓▓▒ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒"
    else
            progBar="▓▓▓▓▓▓▓▓▓▓ ($perc%)"
            longPBar="▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
    fi

}

#Greps timestamp when user closes video
#Arguments:
#$1 - Path to episode
#$2 - seconds|timestamp
#$3 - $timeStamp
playEpisode() {

    episode="$1"

    # if you need to modify mplayer switches, do so on the next line
    stopPos=$(mplayer -fs -ss "$3" "$episode" 2> /dev/null | tr [:cntrl:] '\n' | grep -P "A: +\d+\.\d\b" | tail -n1)

    # decide what to display
    if [ "$2" == "seconds" ]; then
        retval=$(awk '{print $2}' <<< "$stopPos")
    else
        retval=$(awk '{print $3}'  <<< "$stopPos" | tr -d '()')
    fi

}

#Prompt user to pick a show out of a list
obtainSeries() {

    listShows -e
    read -p " 
    Type the number corresponding to the series you would like to watch...

    > " sOption

    if [ "$sOption" == "" ]
    then
            loopMain -e
    fi

}
