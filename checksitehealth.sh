#!/bin/bash
IFS=$'\r\n' GLOBIGNORE='*' command eval 'linesarr=($(cat /sites.txt))'
IFS=','
hostsarr=()
sitenamesarr=()
status_code=''
host=''
sendMail='no'
if [ -f "/logs/scriptoldlog.log" ]
then
    echo "scriptoldlog.log file found."
else
    echo "scriptoldlog.log file created"
    echo -n >/logs/scriptoldlog.log
fi
echo "scriptlatestlog.log file created"
echo -n >/logs/scriptlatestlog.log
echo " "

k='0'
echo "Links to hit : "
for i in "${linesarr[@]}"; do # access each element of array
    read -r -a raw_lines_arr <<< "$i"
    sitenamesarr[$k]=${raw_lines_arr[0]}
    hostsarr[$k]=${raw_lines_arr[1]}
    echo " Site name: ${sitenamesarr[$k]}, Site URL: ${hostsarr[$k]}"
    k=$((k+1))
done

echo " "
read -r -a to_mails_array <<< "$TO_MAILS"
echo "Mail Receipients: "
printf '%s\n' "${to_mails_array[@]}"

IFS=''

echo " "
(
echo "From: noreply@opt.com"
echo "To: ${to_mails_array[0]}"
echo "Subject: OPT server status alert"
echo "Content-Type: text/html"
echo
echo "<html>
<head>
<title>Status of the jobs during the day</title>
<style>
table, th, td {
    border: 1px solid blue;
    border-collapse: collapse;
}
th, td {
    padding: 5px;
}
</style>
</head>
<body>
<table style='width:100%'>
<tr bgcolor='#808080'>
     <th>Site name</th>
     <th>Site Address</th>
     <th>Status code</th>
    <th>Time</th>
    
   
    
</tr>") | cat > demo_1.txt
k='0'
for host in "${hostsarr[@]}"
do
        echo "Site name: ${sitenamesarr[$k]}, Site URL: $host"
        host=${host%$'\r'}
        status_code=$(curl  -sS  -I ${host} 2> /dev/null | head -n 1 | cut -d' ' -f2)
        sleep 30
        echo "URL hit count: 1, Status code: $status_code, host: $host"  
        if [ "$status_code" == "302" ] || [ "$status_code" == "301" ]; then
          location_redirection=$(curl  -sS  -I ${host} 2> /dev/null | grep --ignore-case 'Location: ' | cut -d' ' -f2)
          sleep 30
          http_verb=$(echo "${host}" | cut -f1 -d":")
          if [[ ($location_redirection = http://*) || ($location_redirection = https://*) ]]; then
             host=${location_redirection}
             host=${host%$'\r'}
             echo "url Redirecting to: ${host}"
          else
            raw_host=$(echo "${host}" | cut -f3 -d"/")
            host="${http_verb}://${raw_host}${location_redirection}"
            host=${host%$'\r'}
            echo "URL Redirecting to: '${host}'"
          fi
          host=${host%$'\r'}
          status_code=$(curl -sS -I ${host}  2> /dev/null | head -n 1 | cut -d' ' -f2)
          sleep 5
          echo "URL hit count: 1, Status code: ${status_code}, host: $host"
        fi
        for run in {2..3}
        do
            host=${host%$'\r'}
            new_status_code=$(curl -sS -I ${host}  2> /dev/null | head -n 1 | cut -d' ' -f2)
            sleep 30
            echo "URL hit count: $run, Status code: ${new_status_code}, host: $host"
            
            if [ "$status_code" != "$new_status_code" ] ; then
              addToMail="no"
              echo "NOT ADDED to mail draft as above status codes are not stable."
              break
            elif [ "$status_code" == "$new_status_code" ] ; then
              if [ "$run" == "3" ] ; then
                addToMail="yes"
              fi
            fi
        done
        if [ "$addToMail" == "yes" ] ; then
           datetime=$(date)
           if [[ ("$status_code" != "200") && ("$status_code" != "") ]]; then
            (echo "<tr style=\"color:red;\">
             <td>${sitenamesarr[$k]}</td>
              <td>${host}</td>
               <td>${status_code}</td>
            <td>${datetime}</td>
           
           
           
            </tr>") | cat >> demo_1.txt;
            echo "${sitenamesarr[$k]},$status_code" >> /logs/scriptlatestlog.log
            echo "Added to mail draft."
            sendMail='yes'
           elif [[ ("$status_code" == "200") && ("$status_code" != "") ]]; then
              prev_record=$(cat logs/scriptoldlog.log | grep "${sitenamesarr[$k]},")
              IFS=',' read -r -a prev_status_arr <<< "$prev_record"
              if [[ ("${prev_status_arr[1]}" != "200") && ("${prev_status_arr[1]}" != "") ]]; then
                (echo "<tr style=\"color:green;\">
                <td>${sitenamesarr[$k]}</td>
                <td>${host}</td>
                <td>${status_code}</td>
                <td>${datetime}</td>
                </tr>") | cat >> demo_1.txt;
                echo "${sitenamesarr[$k]},$status_code" >> /logs/scriptlatestlog.log
                echo "Previously, ${sitenamesarr[$k]},${prev_status_arr[1]}"
                echo "Currently, ${sitenamesarr[$k]},$status_code"
                echo "Added to mail draft."
                sendMail='yes'
              fi
           fi
        fi
        echo " "
        k=$((k+1))
done
(
echo "</table></body></html>") | cat >> demo_1.txt
if [ "$sendMail" == "yes" ] ; then
for index in "${to_mails_array[@]}"
do
  sed "2s/.*/To: ${index}/" demo_1.txt > demo_2.txt
  echo " Mail is sent to $index"
  cat demo_2.txt | /usr/sbin/sendmail -t
  rm demo_2.txt;
done
echo "New script logs are stored in scriptoldlog.log file"
cp /logs/scriptlatestlog.log /logs/scriptoldlog.log
rm /logs/scriptlatestlog.log 
fi

rm demo_1.txt