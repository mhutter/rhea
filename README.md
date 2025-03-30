# rhea GitOps

## Secrets

Secrets are managed using the [1Password Kubernetes Operator](https://developer.1password.com/docs/k8s/operator/).

NOTE: When extracting the Item ID from the URL, note that the URL repeats the Vault ID:

    https://my.1password.com/app#/XXX/AllItems/XXXYYY

where `XXX` is the Vault ID, and `YYY` the Item ID.

## Creating PostgreSQL databases

```sh
APP=someapp
k exec -it psql-0 -- /scripts/createdb.sh $APP
```

## Installing the 1Password operator

Create a "Connect" integration (`Infrastructure Secrets Management` -> `Other`) in the [Developer Tools section](https://my.1password.com/developer-tools/directory). Download the `1password-credentials.json` file and save the generated Token.

```sh
kubectl -n 1password create secret generic op-credentials --from-literal=1password-credentials.json="$(cat 1password-credentials.json)"
kubectl -n 1password create secret generic onepassword-token --from-literal=token=<INSERT_TOKEN_HERE>
```
