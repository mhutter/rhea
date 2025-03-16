# rhea GitOps

## Secrets

The easiest way to generate SealedSecrets is to create a file called `something.secret.yaml`, and then use `make something.sealed-secret.json` to generate the SealedSecret using kubeseal. Make sure to put the Namespace in the Secret yaml, as SealedSecret resources are namespace-specific!

## Creating PostgreSQL databases

```sh
APP=someapp
k exec -it psql-0 -- /scripts/createdb.sh $APP | kubeseal -n $APP
```

## Installing the 1Password operator

Create a "Connect" integration (`Infrastructure Secrets Management` -> `Other`) in the [Developer Tools section](https://my.1password.com/developer-tools/directory). Download the `1password-credentials.json` file and save the generated Token.

```sh
kubectl -n 1password create secret generic op-credentials --from-literal=1password-credentials.json="$(cat 1password-credentials.json)"
kubectl -n 1password create secret generic onepassword-token --from-literal=token=<INSERT_TOKEN_HERE>
```
