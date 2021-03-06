#!/bin/bash
# Main operator - Handles workflow

source ./profiles/default
source optFunctions.sh
source utilities.sh

firstLoop="1"
cwd=$(pwd)

#Declare current working directory globally
declare -g cwd

main() {

    #Clear terminal if first loop of main()
    if [ "$firstLoop" == "1" ]
    then
            clear
            firstLoop=0
    fi

    #Title box
    echo "
    +=======================================+
    |                                       |
    |    Doobert's Series Viewer V1.0.A     |
    |                                       |
    +=======================================+" 

    #Prompt user to either select series or add a new one
    read -p "
    +=======================================+
    |                                       |
    |   Options:    [P] - Profile settings  |
    |               [W] - Watch series      |           
    |               [A] - Add series        |
    |               [L] - List shows        |
    |               [D] - Delete series     |
    |               [I] - Series Info       |
    |               [C] - Clear list        |
    |               [E] - Exit (Saves)      |
    |                                       |
    |   To watch a currently stored show    |
    |   enter the associated number.        |
    |                                       |
    +=======================================+

    > " option

    #PWALDICE switch board, guides user input to optFunctions.sh
    case "$option" in
            "P" | "p") profileManager ;;
            "W" | "w") watchSeries ;;
            "A" | "a") addSeries ;;
            "L" | "l") listShows ;;
            "D" | "d") deleteSeries ;;
            "I" | "i") seriesInfo ;;
            "C" | "c") clearList ;;
            "E" | "e") exitSave ;;
            *) clear && main ;;
    esac
    
}

main
