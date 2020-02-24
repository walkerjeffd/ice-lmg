# USGS Lower Mississippi-Gulf Water Science Center RESTORE Data Visualization Tool

Jeffrey D Walker, PhD <jeff@walkerenvres.com>  
[Walker Environmental Research, LLC](https://walkerenvres.com)


## Project setup

Install dependencies

```sh
yarn install
```

Configuration is set using `.env` files per [vue-cli](https://cli.vuejs.org/guide/mode-and-env.html)

The only configuration variable is `VUE_APP_API_BASEURL`, which is used by `axios` to fetch data.

```
VUE_APP_API_BASEURL="http://localhost:8000/"
```

The default `.env` files can be overriden with `.local` variants (e.g. `.env.development.local`).

## Development Server

```sh
yarn dev # runs both data and serve commands
```

## Production Build

```sh
yarn build
```

## Deployment

Run production build and sync static app files from `./dist` to ecosheds server.

```sh
yarn deploy # runs build first
# or
yarn deploy:app
```

Sync data files to remote server

```sh
yarn deploy:data
```

### Deploying to S3

For deploying to S3, use the AWS CLI:

```sh
yarn build
ln -s ../data dist/data # create symlink ./dist/data -> ./data so that aws s3 sync will upload data files
aws s3 sync dist/ s3://<BUCKET_NAME> --delete
```
