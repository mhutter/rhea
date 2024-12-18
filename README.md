# rhea GitOps

## Creating PostgreSQL databases

```sh
APP=someapp
k exec -it psql-0 -- /scripts/createdb.sh $APP | kubeseal -n $APP
```
