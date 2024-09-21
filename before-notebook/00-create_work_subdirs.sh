#!/bin/bash

echo -e "\e[93m**** Create and link user files and dirs ****\e[38;5;241m"

for subdir in $NEEDED_WORK_DIRS; do
		dir="/home/$NB_USER/work/$subdir"
		ln -sf "$dir" "/home/$NB_USER/$subdir"
        if [ ! -f "$dir" ]; then
        	echo Creating "$dir for user $NB_UID group ${NB_GID}"
        	mkdir -p "$dir"
        fi
		ls -l $dir
		chown -R $NB_USER:$NB_GID "$dir" "/home/$NB_USER/$subdir"
		ls -l $dir
done

for subfile in $NEEDED_WORK_FILES; do
		file="/home/$NB_USER/work/$subfile"
		ln -sf "$file" "/home/$NB_USER/$subfile"
        if [ ! -f "$file" ]; then
        	echo Creating "$file for user $NB_UID group ${NB_GID}"
        	touch "$file"        
        fi
		chown -R $NB_USER:$NB_GID "$file" "/home/$NB_USER/$subdir"
done

# chown -R $NB_USER /shared-data

