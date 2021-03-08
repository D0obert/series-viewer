#!/bain/bash

source ./profiles/config

#This file stores functions to be called by profileManager(), much like 
#optFunctions.sh contains functions to be called by main().

#Adds a new profile and sets it as default
newProfile() {
    
    #Obtain profile name $nProfile
    read -p "
    (Name for new profile)> " nProfile

    #Set $tmp to empty in case this session has already used a tmp array
    #Append new profile in the default index (0)
    tmp=()
    tmp+=("$nProfile")
    
    #Append all other profiles in $profile array to $tmp (sans "default") 
    for i in ${profile[@]}
    do
            if [ "$i" != "default" ]
            then
                    tmp+=("$i")
            fi
    done

    #Append "default to end of array, if all other elements are deleted default
    #will be left in the default index (0)
    #Set $profile array equal to $tmp array
    #Clear list to default new profile (Empty at index 0)
    tmp+=("default")
    profile=(${tmp[@]})
    clearList -e
   
    #Declare all empty attributes to a new profile file. add new name to config
    declare -p profile > ./profiles/config
    declare -p pathArray > ./profiles/$nProfile
    declare -p titleArray >> ./profiles/$nProfile
    declare -p countArray >> ./profiles/$nProfile
    declare -p currentEpArray >> ./profiles/$nProfile
    declare -p statusArray >> ./profiles/$nProfile
    declare -p timeStampArray >> ./profiles/$nProfile
    declare -p totalRuntimeArray >> ./profiles/$nProfile
    declare -p currentRuntimeArray >> ./profiles/$nProfile

    echo "
    New profile \"$nProfile\" created"  

    loopMain

}

switchProfile() {

    #Obtain index to delete
    read -p "
    Type the number corresponding to the profile you want to set as default...
    
    > " dOpt

    #This accounts for when the default profile is at the end of the profile
    #array, since the default index is 0 the input has to be adjusted to select
    #the correct index
    if [ "${profile[0]}" != "default" ]
    then
            ((dOpt=$dOpt-1))
    fi

    #Account for no input, if input is detected, set needed variables
    if [ "$dOpt" == "" ] 
    then
           loopMain -e
    else 
           tmp=()
           dProfile="${profile[$dOpt]}"
           tmp+=("$dProfile")
    fi

    #Append all elements in the profile array (sans $dProfile and default) to
    #the tmp array
    for i in ${profile[@]}
    do
            if [ "$i" != "$dProfile" ]
            then
                    if [ "$i" != "default" ]
                    then
                            tmp+=("$i")
                    fi
            fi
    done

    #Append default to $tmp, equalize $profile and $tmp, save new profile array
    #and reset profile to index 0
    tmp+=("default")
    profile=(${tmp[@]})
    declare -p profile > ./profiles/config
    profile=${profile[0]}

}

deleteProfile() {

    #Obtain index of profile to be deleted
    read -p "
    Type the number corresponding to the profile you want to delete...

    > " dOpt

    #Account for non input, set $tmp to empty in case it has been used before
    #in this session.
    if [ "$dOpt" == "" ]
    then
            loopMain -e
    else
            tmp=()
    fi

    #Correct dOpt if "default" is not in index 0
    if [ "${profile[0]}" != "default" ]
    then
            ((dOpt=$dOpt-1))
    fi

    #Loop through $profile by index and add all elements that arent at the 
    #index matching $dOpt
    for i in "${!profile[@]}"
    do
            name=${profile[$i]}
            if [ "$i" != "$dOpt" ]
            then
                    tmp+=("$name")
            fi
    done

    #Delete save file corresponding to deleted profile
    rm ./profiles/"${profile[$dOpt]}"

    profile=(${tmp[@]})

}
