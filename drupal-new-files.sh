#!/bin/sh

echo "" > report.log

find ./ -maxdepth 1 -name "*\.tar\.gz" -print | cut -c 3- | while read i
do

#       echo "TAR NAME = $i"
  name=$( tar xvfz $i | cut -d "/" -f 1 | tail -n 1 )
#       echo "NAME DIR = $name"
  echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> report.log
  echo "<<< $name >>>" >> report.log

  #check drupal core
  if [ -z $( echo $name | grep "^drupal-[67]\.[0123456789]" ) ] then

    #check module exists
    if [ -z "$(find $1/ -maxdepth 1 -name "$name" -print)" ] then

      #check theme
      if [ $name==$( basename $3 ) ] then
        echo "This is theme!" >> report.log
        diff -rq $name $3 | grep "Only in $3" >> report.log
      else
        echo "NOT FOUND" >> report.log
      fi
    else

      #check for changes
      if [ -z "$(diff -rq $name $1/$name | grep "Only in $1")" ] then
        echo "OK" >> report.log
      else
        diff -rq $name $1/$name | grep "Only in $1" >> report.log
      fi
    fi
  else

    #check core folders
    find $name/ -maxdepth 1 -type d -print |  cut -d "/" -f 2 | while read j
    do
      if [ $j != "sites" ] then
        echo "|||||||| $j ||||||||" >> report.log
        diff -rq $name/$j $2/$j | grep "Only in $2" >> report.log
      fi
    done
  fi

  rm -r $name
done
