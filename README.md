# rhea GitOps

## Secrets

The easiest way to generate SealedSecrets is to create a file called `something.secret.yaml`, and then use `make something.sealed-secret.json` to generate the SealedSecret using kubeseal. Make sure to put the Namespace in the Secret yaml, as SealedSecret resources are namespace-specific!

## Creating PostgreSQL databases

```sh
APP=someapp
k exec -it psql-0 -- /scripts/createdb.sh $APP | kubeseal -n $APP
```
