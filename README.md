Houndstooth / WordPress s3 Backup
=================================

This script is based on [this repo](https://github.com/woxxy/MySQL-backup-to-Amazon-S3)
We've rewritten a few things, mainly just quoted strings correctly for shell scripts and expansion.  We have also added file system backups to the script.  Basically, we didn't just want to backup mysql, we also wanted to backup the WP uploads folder.  This script assumes:
    1. You have your codebase under version control (no need to backup)
    2. You want to backup your MYSQL database to Amazon S3
    3. You want to backup your uploads folder to Amazon S3 because it is not under version control (why would it be?)
    4. Your uploads folder resides in a shared folder outside of the app (we use Capistrano for deployment).

Setup
-----
- Install s3cmd (following commands are for debian/ubuntu, but you can find how-to for other Linux distributions on [s3tools.org/repositories](http://s3tools.org/repositories))

		wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | sudo apt-key add -
		sudo wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list
		sudo apt-get update && sudo apt-get install s3cmd
	
- Get your key and secret key at this [link](https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key)

- Configure s3cmd to work with your account

		s3cmd --configure

- Make a bucket (or skip and use bucket you already have)

		s3cmd mb s3://my-database-backups
	
- Put the wps3backup.sh file somewhere in your server, like `/home/user_name/s3backup`
- Give the file 755 permissions `chmod 755 /home/user_name/s3backup/wps3backup.sh`
- Edit the variables near the top of the wps3backup.sh file to match your bucket and MySQL authentication

Now we're set. You can use it manually:

	#set a new daily backup, and store the previous day as "previous_day"
	sh /home/user_name/s3backup/wps3backup.sh
	
	#set a new weekly backup, and store previous week as "previous_week"
	/home/user_name/s3backup/wps3backup.sh week
	
	#set a new weekly backup, and store previous month as "previous_month"
	/home/user_name/s3backup/wps3backup.sh month
	
But, we don't want to think about it until something breaks! So enter `crontab -e` and insert the following after editing the folders

	# daily MySQL backup to S3 (not on first day of month or sundays)
	0 3 2-31 * 1-6 sh /home/user_name/s3backup/wps3backup.sh day
	# weekly MySQL backup to S3 (on sundays, but not the first day of the month)
	0 3 2-31 * 0 sh /home/user_name/s3backup/wps3backup.sh week
	# monthly MySQL backup to S3
	0 3 1 * * sh /home/user_name/s3backup/wps3backup.sh month

Or, if you'd prefer to have the script determine the current date and day of the week, insert the following after editing the folders

	# automatic daily / weekly / monthly backup to S3.
	0 3 * * * sh /home/user_name/s3backup/wps3backup.sh auto

And you're set. 