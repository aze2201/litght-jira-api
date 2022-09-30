# Limited operations via Jira API v3

Author: Fariz Muradov

Mail: aze2201@gmail.com


```
-a              Account ID
-N              Full Name, this ususally need when you make ticket
-e              Owner Jira email
-t              Owner Jira token
-I              Issue type on Jira. i.e Task
-P              Project ID on Jira
-U              URL of issue
-C              Comment on Jira ticket
-d              Dismiss flag 0 or 1. If -d 1 then provided ticket will dismissed
```

### EXAMPLE:
```
./main.sh \
        -a "<accountID> " \
        -e "aze2201@gmail.com" \
        -N "Fariz Muradov"
        -t "<Token>" \
        -I "<IssueTypeID>" \
        -P "<ProjectI?D>" \
        -U "<JIRA URL>/rest/api/3/issue/17058" \
        -C "Cpu is very high on device. More than 90%" \
        -d 0 \
        -m "HIGH CPU on IoT sensor: DeviceN"
```


## You can use below URL to get necessary inforation/IDs about JIRA:

### Get project ID by Project name:

```
 $ curl -s --url "https://<JIRA URL>/rest/api/3/project" \
   --user "<EMAIL>:<TOKEN>"      \
   --header "Accept: application/json" \
   --header "Content-Type: application/json" | jq ".[] | select(.key=="<PROJECT KEY>")" | jq .id"
```

       
### Get issue type ID by Project ID (Task, Bug, etc.):
       
``` 
$ curl -s --url "https://<JIRA URL>/rest/api/3/project/<PROJECT ID>" \
   --user  "<EMAIL>:<TOKEN>" \
   --header "Accept: application/json" \
   --header "Content-Type: application/json" | jq ".issueTypes" | jq ".[] | select(.name=="Task")
```

### Get Account ID information:
 On browser or curl (via auth):

```
 https://<JIRA URL>/rest/api/latest/user/search?query=<JIRA EMAIL>
```

## License
[MIT](https://choosealicense.com/licenses/mit/)
