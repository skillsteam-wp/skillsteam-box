prepare:
	./prepare.sh

up:
	./launch.sh up

up-s3:
	./launch.sh up-s3

down:
	./launch.sh down

down-s3:
	./launch.sh down-s3


backup_db:
	./backup.sh backup

restore_db:
	./backup.sh restore