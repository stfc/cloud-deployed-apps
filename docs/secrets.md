# Secrets

## Overview
Secrets are handled by SOPS, this breaks the chicken-egg problem of installing a secret to access secrets on vault...etc.
age is used to encrypt the secrets, and helm-secrets is used to decrypt them within ArgoCD

## Setup
- Install SOPS: https://github.com/getsops/sops
- Install age: https://github.com/FiloSottile/age or apt-get install age for 22.04+
- Generate a personal private key for age:

```bash
mkdir -p ~/.config/sops/age
age-keygen >> ~/.config/sops/age/keys.txt
```

- (Optional) set your preferred editor, e.g.
```bash
export EDITOR="code --wait"
```

## Adding a new secret

The .sops.yaml file is used to specify which public keys get automatically associated with the encrypted file. 
Note: You do not need access to a private key to encrypt a file, only to decrypt it. This means secrets can be added for prod write-only.

- Add yours to the relevant sections in `secrets/dev/.sops.yaml`
- Add or edit your secret as follows:

```bash
cd secrets/dev  # Currently we have to be in the same dir
sops example-secret.yaml
```

## ArgoCD Integration

ArgoCD needs access to the private key to decrypt the secrets. This is done by adding the private key to the ArgoCD application as a secret:

```bash
kubectl -n argocd create secret generic helm-secrets-private-keys --from-file=key.txt=age-key.txt
```


## VSCode integration

An extension exists for SOPS for vscode that will automatically decrypt/encrypt files. 

You can find it here: https://github.com/signageos/vscode-sops
