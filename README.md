# Workspaces App
Docs, scripts and Terraform templates to use with Workspaces app
## Usage (WIP)
```
git clone https://github.com/rodriguezst/workspaces-app
cd workspaces-app
docker compose up -d
docker compose logs | grep try.coder.app
```
Open https://*.try.coder.app in a browser and create an account using github SSO or email/password.

Go to https://*.try.coder.app/cli-auth and copy the token
```
docker compose exec coder coder login
```
Paste token copied before
```
docker compose exec coder init-templates
```
Go to https://*.try.coder.app/settings/tokens and generate a token

Open Workspaces app and login using https://*.try.coder.app and generated token
