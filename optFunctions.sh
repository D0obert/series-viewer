#!/bin/bash

source ./profiles/default

#Option functions - Main options available to user are processed here

profileManager() {

    echo "Works"
    loopMain 

}


watchSeries() {

    #Obtain index number to use to parse arrays $wOpt
    obtainSeries
    wOpt=$sOption

    #Set all "Attribute" related variables
    path=${pathArray[$wOpt]}
    title=${titleArray[$wOpt]}
    cEp=${currentEpArray[$wOpt]}
    tStamp=${timeStampArray[$wOpt]}
    wStatus=${statusArray[$wOpt]}
    CRT=${currenRuntimeArray[$wOpt]}

    #Set any other needed variables
    epArray=("empty")
    session=0

    #Give the user the chance to start the series at a specific episode number
    if [ "$wStatus" == "Added" ]
    then
            #Set series status to watching and create an empty tmp array
            wStatus="Watching"
            maxIndex=${#statusArray[@]}
            updateAttribute -s "$maxIndex" "$wOpt" "$wStatus"
            statusArray=(${tmp[@]})

            read -p "
    Start at episode 1?

    (Y/N)> " ans && yesNo "$ans" return setcEp 
    fi

    #Populate epArray with the paths of all files found in $path
    cd "$path"
    for i in ./*
    do
            #Only append $i to $epArray if it is a supported file format
            ext="${i##*\.}"
            case $ext in
                    "mkv")epArray+=("$i") ;;
                    "mp4")epArray+=("$i") ;;
            esac
    done

    #Loop through epArray by index, play episode at the correct index $cEp
    for i in ${!epArray[@]}
    do
            #Play episode and prompt user to play next or save position
            if [ "$i" == "$cEp" ]
            then
                    session=1
                    #Set $episode to avoid bad substitution, play episode at 
                    #current timestamp parsed with $wOpt
                    episode="${epArray[$i]}"
                    playEpisode "$episode" "seconds" "$tStamp"
                    #Prompt user to either watch next or stop watching
                    read -p "
    +=======================================+
    |                                       |
    |          Playback has ended.          |
    |                                       |
    |   [ENTER] - Watch next episode        |
    |   [S] - Stop here and save progress   |
    |   [N] - Stop here and watch next      |
    |         episode next session          |
    |                                       |
    +=======================================+

    > " pOpt
            fi

            #Only run case if a session has been started
            if [ "$session" == "1" ] 
            then
                    case "$pOpt" in
                           "S" | "s") #Only save timestamp
                               tStamp=$retval 
                               save=1 ;;
                           "N" | "n") #Reset timestamp and increment $cEp
                               ((cEp+=1))
                               tStamp="0.0"
                               save=1 ;;
                           "") tStamp="0.0" && ((cEp+=1)) ;;
                           *) return ;;
                    esac

                    #Update currentEpArray amd timeStampArray
                    if [ "$save" == "1" ] 
                    then
                               maxIndex=${#currentEpArray[@]}
                               updateAttribute -ce "$maxIndex" "$wOpt" "$cEp"
                               currentEpArray=(${tmp[@]})
                               updateAttribute -ts "$maxIndex" "$wOpt" "$tStamp"
                               timeStampArray=(${tmp[@]})
                               loopMain -e 
                    fi
            fi
                            
    done
    
}

addSeries() {

    #When adding an "Atribute" to the faux data object, you must update all
    #functions handling the data object .The list of functions to update
    #are as below:
    #
    #   1. addSeries()
    #   2. deleteSeries()
    #   3. clearList()
    #   4. exitSave()
    #   5. updateAttribute() (Located in utilities.sh)
    #
    #All sections of code that need to be updated when adding an attribute 
    #Will be marked with [UPDATE ATTRIBUTE] 

    #Obtain $path
    read -p "
    Please drag file containing series into the temrinal and press ENTER...

    > " path

    #Account for non-input and loopmain if no path is given
    if [ "$path" == "" ]
    then
            loopMain -e
    fi

    #Default $epCount and $title
    epCount=0
    title=""

    #Remove single quotes from $path and obtain epCount and title
    path=$(echo $path | tr -d "'")
    echo "
    Adding..."
    parsePath "$path"

    #==========================[UPDATE ATTRIBUTE]==========================#

    #Create "Object" by appending all "Attributes" to the same relative index
    pathArray+=( "$path" )
    titleArray+=( "$title" )
    countArray+=( $epCount )
    currentEpArray+=( 1 )
    statusArray+=( "Added" )
    timeStampArray+=( "0.0" )
    totalRuntimeArray+=( "$totRunTime" )
    currentRuntimeArray+=( "0.0" )

    ((totObj=${#pathArray[@]}-1))
    seriesInfo -e $totObj

    #Prompt user to add a number and loop addSeries if so, loopMain if not
    read -p "
    Would you like to add another?

    (Y/N)> " ans

    yesNo "$ans" addSeries return

    loopMain -e

}

listShows() {

    sCount=0

    #List all strings in $titleArray numerically
    echo "
    Currently stored shows:
    "

    #loop throug titleArray and echo each element
    for i in ${!titleArray[@]}
    do
        if [ "${titleArray[$i]}" != "empty" ]
        then
                updateProgBar ${currentEpArray[$i]} ${countArray[$i]} ${statusArray[$i]} 
                ((sCount+=1))
                echo "      $sCount. $progBar ${titleArray[$i]##*/}"
        fi
    done

    #Escape loopMain if further actions are needed after listing
    if [ "$1" != "-e" ]
    then
        loopMain
    fi

}

#Deleting a series works in a few steps:
#
#   1. Obtain index of "Object" that needs to be deleted
#   2. Create an empty temporary array and obtain total number of "Objects"
#   3. Loop through all of the data arrays (Attribute) BY INDEX (Object)
#   4. For each "Attribute", check all "Object" index numbers against the 
#      number obtained in step 1, if they are not, add the current "Object's"
#      "Attribute" to the temporary array.
#   5. When the "Object" index number reaches the total number of "Objects"
#      found in step 2, equalize current "Attribute" array and the temp array.
#   6. Clear the temp array and increment the marker indicating what "Attribute"
#      the loop is on
#
#This whole process essentially loops through all "Attribute" arrays and removes
#the "Object" located at a user specified index.

deleteSeries() {

    obtainSeries
    delOption=$sOption
    title=${titleArray[delOption]}

    #Confirm correct series was chosen
    read -p "
    Are you sure you want to remove $title from the list?

    (Y/N) > " ans

    yesNo "$ans" return loopMain

    #Set defaults 
    tmp=()
    objCount=${#titleArray[@]}
    currObj=0
    currAttr=1

    #==========================[UPDATE ATTRIBUTE]==========================#

    #Increment if new attribute is added
    attrCount=8

    #Add any new attributes to args in identical format ${!<attributeName>[@]}
    for i in ${!pathArray[@]} ${!titleArray[@]} ${!countArray[@]} ${!currentEpArray[@]} ${!statusArray[@]} ${!timeStampArray[@]} ${!totalRuntimeArray[@]} ${!currentRuntimeArray[@]}
    do
            ((currObj+=1))

            #Only add to tmp if current index is not the index the user chose
            if [ "$i" != "$delOption" ]
            then
                    #==================[UPDATE ATTRIBUTE]==================#
                    case $currAttr in
                            1) tmp+=(${pathArray[$i]})            ;;
                            2) tmp+=(${titleArray[$i]})           ;;
                            3) tmp+=(${countArray[$i]})           ;;
                            4) tmp+=(${currentEpArray[$i]})       ;;
                            5) tmp+=(${statusArray[$i]})          ;;
                            6) tmp+=(${timeStampArray[$i]})       ;;
                            7) tmp+=(${totalRuntimeArray[$i]})    ;;
                            8) tmp+=(${currentRuntimeArray[$i]})  ;;
                    esac
            fi

            #This is run every time all "Objects" in a certain "Attribute" have
            #been appended to tmp (sans the user specified "Object") to update
            #each "Attribute" set to the set that does not include that "Object"
            if [ "$currObj" == "$objCount" ]
            then
                    #==================[UPDATE ATTRIBUTE]==================#  
                    case $currAttr in
                            1)pathArray=(${tmp[@]})           ;;
                            2)titleArray=(${tmp[@]})          ;;
                            3)countArray=(${tmp[@]})          ;;
                            4)currentEpArray=(${tmp[@]})      ;;
                            5)statusArray=(${tmp[@]})         ;;
                            6)timeStampArray=(${tmp[@]})      ;;
                            7)totalRuntimeArray=(${tmp[@]})   ;;
                            8)currentRuntimeArray=(${tmp[@]}) ;;
                    esac
                    #Reset defaults and increment $currAttr
                    tmp=()
                    currObj=0
                    ((currAttr=$currAttr+1))
            fi
    done

    #Inform user operation was finished (Note, these changes have not been
    #applied to the profile yet, the user will have to exit. However, the 
    #changes are reflected in the current session)
    echo  "
    Removed $title from the list"
    
    loopMain

}

#Initialize data structure. Any future "object attributes" are set to empty here
clearList() {

    #Confirm before proceeding
    read -p "
    Are you sure you want to completely reset the list?

    (Y/N) > " ans

    yesNo "$ans" return "loopMain -e"

    #==========================[UPDATE ATTRIBUTE]==========================# 

    #New attributes must be set as an array with index 0 = "empty"
    pathArray=("empty")
    titleArray=("empty")
    countArray=("empty")
    currentEpArray=("empty")
    statusArray=("empty")
    timeStampArray=("empty")
    totalRuntimeArray=("empty")
    currentRuntimeArray=("empty")

    loopMain -e

}

#Provide the user with attributes of a specific series
#Arguments:
#$1 - -e (Escape list and prompt)
#$2 - $iOption
seriesInfo() {

    escape="$1"

    if [ "$escape" != "" ]
    then
            iOption="$2"
    fi

    #List all shows and prompt the user to pick one 
    if [ "$escape" == "" ]
    then
            listShows -e
            read -p "
    Type the number corresponding to the series you would like more info on...

    > " iOption
    fi

    #loopMain if no input is given
    if [ "$iOption" == "" ] 
    then
            loopMain -e
    fi

    #Correct current episode number
    cEp=${currentEpArray[$iOption]}
    updateProgBar $cEp ${countArray[$iOption]} ${statusArray[$iOption]} 

    #Display all relevant information of selected series
    echo "
    Title: ${titleArray[$iOption]}
    Number of episodes: ${countArray[$iOption]}
    Current Episode: $cEp 
    Timestamp of current episode: ${timeStampArray[$iOption]}
    Status: ${statusArray[$iOption]}"

    if [ "$escape" == "" ]
    then
        loopMain
    fi
}

#This function commits any changes made to the profile 
exitSave() {

    #Ensure user is in origial working directory before saving
    cd $cwd

    #Declare $pathArray as > to clear profile and replace with only $pathArray
    #Declare the rest as >> to add onto profile without overwriting original
    #This accomlishes a fresh "Data set" every exit that is up to date. The
    #elements of each array have been added in a way that each "object" is 
    #represented as an array index. This can be represented by a matrix where 
    #each column is an object and each row of that column is an attribute:
    #                                              #
    #                         Objects↓             #
    #         Attributes↓    1     2   3..         #
    #                Path ["ex1","ex2",...]        #
    #               Title ["ex1","ex2",...]        #
    #               Count [exNum,exNum,...]        #
    #          Current EP [exNum,exNum,...]        #
    #        Watch Status ["ex1","ex2",...]        #
    #                 ... ["...","...",...]        #
    #                                              #
    #==============[UPDATE ATTRIBUTE]==============#
    
    declare -p pathArray > ./profiles/default
    declare -p titleArray >> ./profiles/default
    declare -p countArray >> ./profiles/default
    declare -p currentEpArray >> ./profiles/default
    declare -p statusArray >> ./profiles/default
    declare -p timeStampArray >> ./profiles/default
    declare -p totalRuntimeArray >> ./profiles/default
    declare -p currentRuntimeArray >> ./profiles/default

    exit 1
}
