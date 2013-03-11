#!/bin/sh

# Based on: https://github.com/woxxy/MySQL-backup-to-Amazon-S3 - Under a MIT license

PROJECTNAME="{{projectname}}"
# MYSQL Stuff
MYSQL_USER="{{mysqluser}}"
MYSQL_PASS="{{mysqlpass}}"
MYSQL_DATABASE="{{mysqldb}}"

# Stuff for S3 Bucket
S3BUCKET="{{s3bucket}}"

MYSQLDUMP_PATH=`which mysqldump`
MYSQL_S3PATH="mysql/"
DB_FILENAME="${PROJECTNAME}_db"

# File System Backups
SYSTEM_PATH="/home/{{user}}/public/{{domain}}/public/shared"
SYSTEM_S3PATH="system/"
SYSTEM_FILENAME="${PROJECTNAME}_system"

# tmp path
TMP_PATH="/home/{{user}}/tmp/"

################################
## Ok that's it, stop editing ##
################################

DATESTAMP="$(date +".%m.%d.%Y")"
DAY="$(date +"%d")"
DAYOFWEEK="$(date +"%A")"

PERIOD=${1-day}
if [ ${PERIOD} = "auto" ]; then
        if [ ${DAY} = "01" ]; then
                PERIOD=month
        elif [ ${DAYOFWEEK} = "Sunday" ]; then
                PERIOD=week
        else
                PERIOD=day
        fi
fi

echo "Selected period: $PERIOD."

echo "Starting backing up the database to a file..."

# dump all databases
${MYSQLDUMP_PATH} --quick --user=${MYSQL_USER} --password=${MYSQL_PASS} ${MYSQL_DATABASE} > ${TMP_PATH}${DB_FILENAME}.sql

echo "Done backing up the database to a file."
echo "Starting compression..."

tar czf ${TMP_PATH}${DB_FILENAME}${DATESTAMP}.tar.gz ${TMP_PATH}${DB_FILENAME}.sql
tar zcvf ${TMP_PATH}${SYSTEM_FILENAME}${DATESTAMP}.tar.gz ${SYSTEM_PATH}/uploads

echo "Done compressing the backup files."

# we want at least two backups, two months, two weeks, and two days
echo "Removing old backups (2 ${PERIOD}s ago)..."
s3cmd del --recursive s3://${S3BUCKET}/${MYSQL_S3PATH}previous_${PERIOD}/
s3cmd del --recursive s3://${S3BUCKET}/${SYSTEM_S3PATH}previous_${PERIOD}/
echo "Old backups removed."

echo "Moving the backups from past $PERIOD to another folder..."
s3cmd mv --recursive s3://${S3BUCKET}/${MYSQL_S3PATH}${PERIOD}/ s3://${S3BUCKET}/${MYSQL_S3PATH}previous_${PERIOD}/
s3cmd mv --recursive s3://${S3BUCKET}/${SYSTEM_S3PATH}${PERIOD}/ s3://${S3BUCKET}/${SYSTEM_S3PATH}previous_${PERIOD}/
echo "Past backups moved."

# Upload backups
echo "Uploading the new backups..."
s3cmd put -f ${TMP_PATH}${DB_FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${MYSQL_S3PATH}${PERIOD}/
s3cmd put -f ${TMP_PATH}${SYSTEM_FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${SYSTEM_S3PATH}${PERIOD}/
echo "New backups uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ${TMP_PATH}${DB_FILENAME}.sql
rm ${TMP_PATH}${DB_FILENAME}${DATESTAMP}.tar.gz
rm ${TMP_PATH}${SYSTEM_FILENAME}${DATESTAMP}.tar.gz
echo "Files removed."
echo "All done."