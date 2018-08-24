
# To deploy

- For production:
```bash
git remote add api dokku@apps.alces-flight.com:flight-blueprint-api
git remote add client dokku@apps.alces-flight.com:flight-blueprint-client

git push api
git push client
```

- For staging:
```bash
git remote add api-staging dokku@apps.alces-flight.com:flight-blueprint-api-staging
git remote add client-staging dokku@apps.alces-flight.com:flight-blueprint-client-staging

git push api-staging
git push client-staging
```
