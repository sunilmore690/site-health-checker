1. ensure that 25 port is not engaged in other activities
2. Run command inside this folder path 'docker-compose up -d'
3. file.txt is volume shared file: Where site urls are written
4. checksitehealth2.sh is volume shared file: Script to send mail
5. credentials-smtp.env is environment file: where smtp server host, user and password are specified
6. IMP: In credentials-smtp.env SMTP_PASSWORD is app password created in google account
7. We can setup cron like 'docker exec docker-sitechecker_postfix_1 bash /checksitehealth2.sh' 
   store scripts logs set cron job like -->
	  'docker exec docker-sitechecker_postfix_1 bash /checksitehealth2.sh > /logs/script.log'
   accumulate all scripts ERROR logs only into file  -->
	  'docker exec docker-sitechecker_postfix_1 bash /checksitehealth2.sh >> /logs/script.log 2>&1'

#A note about using gmail as a relay
Gmail by default does not allow email clients that don't use OAUTH 2 for authentication (like Thunderbird or Outlook). First you need to enable access to "Less secure apps" on your google settings.

Also take into account that email From: header will contain the email address of the account being used to authenticate against the Gmail SMTP server(SMTP_USERNAME), the one on the email will be ignored by Gmail.