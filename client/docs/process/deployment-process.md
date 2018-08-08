# Overview of deployment process

## Prerequisites

- A checked out copy of the flight-terminal-services-client git repo.
- Some git remotes which can be created with:
  - `git remote add dokku dokku@apps.alces-flight.com:flight-terminal-services-client`
  - `git remote add dokku-staging dokku@apps.alces-flight.com:flight-terminal-services-client-staging`
- Some unix tools: `ruby` and `jq`.

## How to deploy a branch to production.

To deploy a new release of Flight Terminal Services Client follow the
instructions below:

1.  Checkout the branch you wish to deploy.
2.  Run `./bin/deploy-and-release.sh`.
3.  Press enter when prompted (there will be 3 prompts to do so) and save
    commit messages to merge to develop and master.
4.  There is no step 4.

## What does deploy-and-release.sh do?

1.  Checks that there are no uncommited changes.
2.  Determines the next tag to use (e.g., 201704.15).
3.  Creates a new release branch (e.g., release/201704.15).
4.  Bumps the version file used by the terminal services client.
5.  Runs `./bin/deploy.sh` to deploy the app to staging.
6.  Runs `./bin/deploy.sh --production` again to deploy the app to production.
7.  Merges, tags and pushes to github.

## What does deploy.sh do?

Running `./bin/deploy.sh` does the following:

1.  Checks that there are no uncommited changes.
2.  Pushes the repo to the appropriate dokku remote.
3.  The dokku remote builds the application using the standard node build
    pack.

When given the `--production` argument, the appropriate remote will be the
production dokku; otherwise it deploys to the staging dokku app.

## What can go wrong and how do we fix it?

If everything goes well, running the `./bin/deploy-and-release.sh` script is
all that is needed. If there is a problem, intervention may be required.

**Something didn't work. What do I do?** Contact Ben tell him to deploy
the release and update this document with details of the problem and solution.
