# The REKKI command-line

REKKI has a dedicated Platform Team in charge of building a robust foundation
that can be leveraged by the Tech & Product teams. Part of this foundation is
the Developer Experience. To that end, we are developping an in-house CLI that
allows the engineers to easily interact with our stack.

## Table of Contents

- [Introduction](#introduction)
- [Install & Update](#install-update)
- [System-wide Commands](#system-wide-commands)
  - [`rekki init`](#rekki-init)
  - [`rekki shellenv`](#rekki-shellenv)
  - [`rekki whoami`](#rekki-whoami)
- [Repository Commands](#repository-commands)
  - [`rekki clone`](#rekki-clone)
- [Services/Jobs Development Commands](#services-jobs-development-commands)
  - [`rekki deploy`](#rekki-deploy)
  - [`rekki diff`](#rekki-diff)
  - [`rekki run`](#rekki-run)
- [Services/Jobs Management Commands](#services-jobs-management-commands)
  - [`rekki delete`](#rekki-delete)
  - [`rekki env`](#rekki-env)
  - [`rekki history`](#rekki-history)
  - [`rekki logs`](#rekki-logs)
  - [`rekki pods`](#rekki-pods)
  - [`rekki restart`](#rekki-restart)
  - [`rekki rollback`](#rekki-rollback)
- [Services/Jobs Browser Commands](#services-jobs-browser-commands)
  - [`rekki aws:secrets`](#rekki-aws-secrets)
  - [`rekki dd:apm`](#rekki-dd-apm)
  - [`rekki dd:containers`](#rekki-dd-containers)
  - [`rekki dd:errors`](#rekki-dd-errors)
  - [`rekki dd:logs`](#rekki-dd-logs)
  - [`rekki dd:metrics`](#rekki-dd-metrics)
  - [`rekki dd:pods`](#rekki-dd-pods)
  - [`rekki dd:ps`](#rekki-dd-ps)
  - [`rekki dd:traces`](#rekki-dd-traces)
- [Cluster Commands](#cluster-commands)
  - [`rekki repl`](#rekki-repl)
  - [`rekki ssh`](#rekki-ssh)
  - [`rekki tunnel`](#rekki-tunnel)
- [Other Commands](#other-commands)
  - [`rekki docs`](#rekki-docs)
  - [`rekki flare`](#rekki-flare)
  - [`rekki help`](#rekki-help)
  - [`rekki version`](#rekki-version)
- [Topics](#topics)
  - [Feedbacks & Issues](#feedbacks-issues)
  - [Options & Environment](#options-environment)
  - [Resources](#resources)
  - [Services & Jobs](#services-jobs)

## Introduction

This CLI is a companion used by REKKI engineers to improve their day-to-day
workflow. It takes care from everything from installing the required system
dependencies to providing an efficient and easy-to-use hot-reloading mecanism.

## Install & Update

To download the latest release and set up your system:

    curl --proto '=https' --tlsv1.2 -sSf https://cli.rekki.team/install.sh | bash

To keep your system up to date after the first install:

    rekki init

## System-wide Commands

### `rekki init`

> Initialize the ~/.rekki directory.

The initialization is composed of the following steps:

 1. update the CLI
 2. install the Xcode command line tools (macOS only)
 3. load your SSH key
 4. check that the SSH key can be used to log in a GitHub account; and make
    sure your AWS credentials are valid
 5. generate the kubernetes configuration
 6. generate the ephemeral ssh keys
 7. fetch the latest version of https://github.com/rekki/devops
 8. install the system dependencies with the proper versions
 9. install the go dependencies with the proper versions
10. alias `rekki` to `rk`

This command is idempotent. You can, and should, run it as often as you need.

#### Usage

```
rekki init [options]
```

_aliased as `rekki update`, `rekki upgrade`_

#### Options

```
    --no-banner        true to disable the REKKI banner
    --no-self-update   true to disable the CLI self update
    --version string   specific commit to install instead of the latest release
```

#### Examples

```shell
# Initialize or update your machine
rekki init

# Initialize or update your machine, but skip the CLI self update
rekki init --no-self-update
```

### `rekki shellenv`

> Print export statements.

These export statements have to be imported in your shell environment for this
CLI to work properly.

#### Usage

```
rekki shellenv
```

#### Examples

```shell
# Add this to your ~/.zprofile to integrate with your shell:
eval "$("$HOME/.rekki/bin/rekki" shellenv)"
```

### `rekki whoami`

> Output the identities you are logged with.

Check AWS and GitHub and print the accounts your are logged with on stdout.

#### Usage

```
rekki whoami
```

#### Examples

```shell
# Print your identities
rekki whoami
```

## Repository Commands

### `rekki clone`

> Clone a REKKI repository into a new directory.

Clone clones the remote repository. It is possible to only provide the
repository name, in which case it will clone from the REKKI GitHub
organization. It creates the remote-tracking branches for the master branch
only.

#### Usage

```
rekki clone [options] <repository> [directory]
```

#### Examples

```shell
# Clone the git@github.com:rekki/go.git repository into ./go
rekki clone go

# Clone the git@github.com:rekki/go.git repository into /tmp/go-tmp
rekki clone go /tmp/go-tmp

# Clone the https://github.com/golang/go.git repository into /tmp/rekki-go
rekki clone https://github.com/golang/go.git /tmp/golang-go
```

## Services/Jobs Development Commands

### `rekki deploy`

> Deploy the service or job.

Deploy the current REKKI service or job into a cluster.

First it will send the request to Sauron (our internal builder service) to
build the docker image and publish it to our AWS ECR Docker repository.

In order for a build to happen your current directory must:

- contain a Dockerfile
- be part of a Rekki owned git repository (or worktree of a repository)

When Sauron is finished building and pushing to ECR, 
it will take care of creating a new Helm release into the
cluster.

#### Usage

```
rekki deploy [options]
```

#### Options

```
    --allow-dirty         allow to deploy with a dirty git state
    --force               force the helm deploy
    --sauron-url string   the url of the sauron service (default "https://sauron.rekki.team")
    --version string      git commit to be deployed (default to using the current git head)
```

#### Examples

```shell
# Deploy the hulk service on the feat environment
cd go/cmd/hulk && rekki deploy

# Deploy the hulk service on the live environment
cd go/cmd/hulk && rekki deploy -nlive

# Deploy a non-go application
cd alfred && rekki deploy

# Deploy a custom version of the hulk service on the live environment
cd go/cmd/hulk && rekki deploy -nlive --version=a8287fcf155f8ed70808d260d9ac8d05491372cf
```

### `rekki diff`

> Display diff between local and deployed code.

Diff uses the current git head code, and compares it with the remote code
deployed for the service or job.

#### Usage

```
rekki diff [options]
```

#### Examples

```shell
# Diff hulk on feat
cd go/cmd/hulk && rekki diff

# Diff hulk on live
cd go/cmd/hulk && rekki diff -nlive
```

### `rekki run`

> Run the service or job for development.

This command is used to run a service or job locally. This takes care of:

  - fetching the environment variables
  - creating the tunnel to the given resources (by default: DB and Redis)
  - starting the service

This command will try to infer the correct command and arguments when starting
the service. If your need differs from what's been inferred, you can easily
override. See the examples.

If not specified in the `-t` flags, random local ports will be chosen when
additional resources are added to be tunnelled. This behavior diverges from
what you would observe in `rekki tunnel` as the goal here is to allow you to
run several instances of `rekki run` in parallel without having to worry about
port collision. See the examples on how you can force a specific port to be
used.

Note that tunnels to services will automatically populate the `_SERVICE_HOST`
and `_SERVICE_PORT` environment variables.

#### Usage

```
rekki run [options] [-- cmd args...]
```

#### Options

```
    --as string            specify which resource the command should be run as
    --clear                clear screen before executing command
-e, --env strings          set environment variables
    --no-default-tunnels   disable the default tunnels to the database and redis
-t, --tunnel strings       set additional resources for which tunnel must be created
    --watch                watch for changes and autoreload service or job
```

#### Examples

```shell
# Start the hulk service with the feat environment
cd go/cmd/hulk && rekki run

# Start the wasabi service with the live environment
cd go/cmd/wasabi && rekki run -nlive

# Define custom environment variables
cd go/cmd/wasabi && rekki run -e LOG_LEVEL=info

# Define additional resources to be tunnelled
cd go/cmd/wasabi && rekki run -t svc/hulk

# Define additional resources to be tunnelled on a specific local port
cd go/cmd/wasabi && rekki run -t 5423:db/live -t 6379:redis/live

# The name fallbacks to be the namespace if not specified for database and redis (default namespace is feat)
cd go/cmd/wasabi && rekki run -t 5423:db -t 6379:redis

# Start a service with a custom command and arguments
cd go/cmd/wasabi && rekki run -- go run . --admin=true

# Start a service, autoreload and clear screen every time it restarts
cd go/cmd/wasabi && rekki run --watch --clear

# Start a feat service, and tunnel to both a local service on port 9090 and a live service
cd go/cmd/hulk && rekki run -t marketplace-everything@local:9090 -t blackrock-search-grpc@live

# Run a go script with the shared live secret
cd go && rekki run --as=shared@live ./scripts/generate-model.go
```

## Services/Jobs Management Commands

### `rekki delete`

> Delete a service or job.

Delete a service or job by uninstalling the corresponding helm release.

#### Usage

```
rekki delete [options] [resource]
```

#### Examples

```shell
# Delete hulk on feat
cd go/cmd/hulk && rekki delete

# Delete hulk on live
cd go/cmd/hulk && rekki delete -nlive

# Same but can be executed anywhere on your system
rekki delete -nlive hulk
```

### `rekki env`

> Print the environment variables for a service or job.

The environment variables are fetched from AWS Secrets Manager.

#### Usage

```
rekki env [options] [resource]
```

#### Examples

```shell
# Print the environment variables for the wasabi service on feat
cd go/cmd/wasabi && rekki env

# Print the environment variables for the hulk service on live
cd go/cmd/hulk && rekki env -nlive

# Same but can be executed anywhere on your system
rekki env -nlive hulk
```

### `rekki history`

> Show deployments history for a service or job.

List all the deployed Helm releases for a service or job.

#### Usage

```
rekki history [options] [resource]
```

#### Examples

```shell
# Print the history for wasabi in feat
cd go/cmd/wasabi && rekki history

# Print the history for wasabi in live
cd go/cmd/wasabi && rekki history -nlive

# Same but can be executed anywhere on your system
rekki history -nlive wasabi
```

### `rekki logs`

> Fetch logs for a service or job.

Contact the kubernetes cluster to fetch logs for the given service or job.

#### Usage

```
rekki logs [options] [resource]
```

#### Options

```
-f, --follow   specify if the logs should be streamed
```

#### Examples

```shell
# Get logs for wasabi on feat
cd go/cmd/wasabi && rekki logs

# Get logs for wasabi on live
cd go/cmd/wasabi && rekki logs -nlive

# Same but can be executed anywhere on your system
rekki logs -nlive wasabi
```

### `rekki pods`

> List all the pods for a service or job.

Query the cluster to fetch all the pods for the service or job.

#### Usage

```
rekki pods [options] [resource]
```

#### Examples

```shell
# List all the pods for the wasabi service
cd go/cmd/wasabi && rekki pods

# List all the pods for the wasabi service on live
cd go/cmd/wasabi && rekki pods -nlive

# Same but can be executed anywhere on your system
rekki pods -nlive wasabi
```

### `rekki restart`

> Restart the deployments for a service.

Sequentially restart all the pods for all the deployments of the service.

#### Usage

```
rekki restart [options] [resource]
```

#### Examples

```shell
# Restart wasabi on feat
cd go/cmd/wasabi && rekki restart

# Restart wasabi on live
cd go/cmd/wasabi && rekki restart -nlive

# Same but can be executed anywhere on your system
rekki restart -nlive wasabi
```

### `rekki rollback`

> Rollback a service or job to a specific release.

Rollback a service or job deployment to the specific helm release.

#### Usage

```
rekki rollback [options] [resource]
```

#### Examples

```shell
# Rollback hulk on feat
cd go/cmd/hulk && rekki rollback

# Rollback hulk on live
cd go/cmd/hulk && rekki rollback -nlive

# Same but can be executed anywhere on your system
rekki rollback -nlive hulk
```

## Services/Jobs Browser Commands

### `rekki aws:secrets`

> Open AWS Secrets Manager in the default web browser.

Open the interface to manage services and jobs secrets in the default web
browser.

#### Usage

```
rekki aws:secrets [options] [resource]
```

#### Examples

```shell
# Open the AWS Secrets for wasabi in feat
cd go/cmd/wasabi && rekki aws:secrets

# Open the AWS Secrets for wasabi in live
cd go/cmd/wasabi && rekki aws:secrets -nlive

# Same but can be executed anywhere on your system
rekki aws:secrets -nlive wasabi
```

### `rekki dd:apm`

> Open Datadog APM in the default web browser.

Open the Datadog APM interface for the service or job.

#### Usage

```
rekki dd:apm [options] [resource]
```

#### Examples

```shell
# Open the Datadog APM for wasabi in feat
cd go/cmd/wasabi && rekki dd:apm

# Open the Datadog APM for wasabi in live
cd go/cmd/wasabi && rekki dd:apm -nlive

# Same but can be executed anywhere on your system
rekki dd:apm -nlive wasabi
```

### `rekki dd:containers`

> Open Datadog Containers in the default web browser.

Open the Datadog Containers interface for the service or job.

#### Usage

```
rekki dd:containers [options] [resource]
```

#### Examples

```shell
# Open the Datadog Containers for wasabi in feat
cd go/cmd/wasabi && rekki dd:containers

# Open the Datadog Containers for wasabi in live
cd go/cmd/wasabi && rekki dd:containers -nlive

# Same but can be executed anywhere on your system
rekki dd:containers -nlive wasabi
```

### `rekki dd:errors`

> Open Datadog Error Tracking in the default web browser.

Open the Datadog Error Tracking interface for the service or job.

#### Usage

```
rekki dd:errors [options] [resource]
```

#### Examples

```shell
# Open the Datadog Error Tracking for wasabi in feat
cd go/cmd/wasabi && rekki dd:errors

# Open the Datadog Error Tracking for wasabi in live
cd go/cmd/wasabi && rekki dd:errors -nlive

# Same but can be executed anywhere on your system
rekki dd:errors -nlive wasabi
```

### `rekki dd:logs`

> Open Datadog Logs in the default web browser.

Open the Datadog Logs interface for the service or job.

#### Usage

```
rekki dd:logs [options] [resource]
```

#### Examples

```shell
# Open the Datadog Logs for wasabi in feat
cd go/cmd/wasabi && rekki dd:logs

# Open the Datadog Logs for wasabi in live
cd go/cmd/wasabi && rekki dd:logs -nlive

# Same but can be executed anywhere on your system
rekki dd:logs -nlive wasabi
```

### `rekki dd:metrics`

> Open Datadog Metrics in the default web browser.

Open the Datadog Metrics interface for the service or job.

#### Usage

```
rekki dd:metrics [options] [resource]
```

#### Examples

```shell
# Open the Datadog Metrics for wasabi in feat
cd go/cmd/wasabi && rekki dd:metrics

# Open the Datadog Metrics for wasabi in live
cd go/cmd/wasabi && rekki dd:metrics -nlive

# Same but can be executed anywhere on your system
rekki dd:metrics -nlive wasabi
```

### `rekki dd:pods`

> Open Datadog Pods in the default web browser.

Open the Datadog Pods interface for the service or job.

#### Usage

```
rekki dd:pods [options] [resource]
```

#### Examples

```shell
# Open the Datadog Pods for wasabi in feat
cd go/cmd/wasabi && rekki dd:pods

# Open the Datadog Pods for wasabi in live
cd go/cmd/wasabi && rekki dd:pods -nlive

# Same but can be executed anywhere on your system
rekki dd:pods -nlive wasabi
```

### `rekki dd:ps`

> Open Datadog Processes in the default web browser.

Open the Datadog Processes interface for the service or job.

#### Usage

```
rekki dd:ps [options] [resource]
```

#### Examples

```shell
# Open the Datadog Processes for wasabi in feat
cd go/cmd/wasabi && rekki dd:ps

# Open the Datadog Processes for wasabi in live
cd go/cmd/wasabi && rekki dd:ps -nlive

# Same but can be executed anywhere on your system
rekki dd:ps -nlive wasabi
```

### `rekki dd:traces`

> Open Datadog Traces in the default web browser.

Open the Datadog Traces interface for the service or job.

#### Usage

```
rekki dd:traces [options] [resource]
```

#### Examples

```shell
# Open the Datadog Traces for wasabi in feat
cd go/cmd/wasabi && rekki dd:traces

# Open the Datadog Traces for wasabi in live
cd go/cmd/wasabi && rekki dd:traces -nlive

# Same but can be executed anywhere on your system
rekki dd:traces -nlive hulk
```

## Cluster Commands

### `rekki repl`

> Start a REPL to a remote resource.

Start a read–eval–print loop with a remote resource (only postgres is supported
at the moment).

#### Usage

```
rekki repl [options] <resource>
```

#### Examples

```shell
# repl the feat database
rekki repl db

# repl the live database
rekki repl db/live
```

### `rekki ssh`

> Open an interactive SSH session to a remote resource.

Using either a tunnel through our bastion instance or kubectl exec, an
interactive session is being started on a remote resource.

#### Usage

```
rekki ssh [options] <resource>
```

#### Examples

```shell
# ssh to the bastion instance
rekki ssh bastion

# ssh to a hulk service pod on feat
rekki ssh svc/hulk

# ssh to a hulk service pod on live
rekki ssh svc/hulk -nlive
```

### `rekki tunnel`

> Create SSH tunnels to remote resources.

Create a tunnel between your local machine and a remote resource. This can be
used to access database and redis instances, but also kubernetes pods,
services, replica sets and deployments.

If no ports are specified, then the default protocol ports will be used:

  - 5432 for postgres
  - 6379 for redis
  - 8080 for HTTP tunnels to Kubernetes resources (as port 80 usually requires root)

#### Usage

```
rekki tunnel [options] <resources...>
```

#### Examples

```shell
# Create a tunnel to the live database
rekki tunnel -nlive db

# Create a tunnel to the live redis instance
rekki tunnel -nlive redis

# Create tunnels to the live database and hulk service
rekki tunnel -nlive db svc/hulk

# Create a tunnel to the feat hulk service
rekki tunnel svc/hulk

# Create a tunnel to the live hulk service on local port 9090
rekki tunnel -nlive 9090:svc/hulk

# Create a tunnel to a specific database
rekki tunnel db/feat-xxxxx
```

## Other Commands

### `rekki docs`

> Print a complete documentation for the CLI.

Generates a complete documentation for this command-line, including
documentation for all the commands and all the topics. Output will be printed
on stdout and will be Markdown by default. It is possible to output HTML by
supplying the `--html` flag. It is also possible to serve the HTML
documentation to be consumed from your web browser with `--serve`.

#### Usage

```
rekki docs [options]
```

#### Options

```
    --html          produce html instead of markdown
-p, --port uint16   port to listen on when serving doc (default 4242)
    --serve         serve HTML documentation
```

#### Examples

```shell
# Print markdown documentation on the standard output
rekki docs

# Print HTML documentation on the standard output
rekki docs --html

# Serve HTML documentation via an http server (http://localhost:4242)
rekki docs --serve

# Serve HTML documentation via an http server (http://localhost:9090)
rekki docs --serve -p 9090
```

### `rekki flare`

> Send a debug trace to the #rekki-cli-flares Slack channel.

It is being used by the Platform team to investigate a bug you might be facing.
This is automatically done whenever an error or panic occurs.

#### Usage

```
rekki flare [-- args...]
```

#### Examples

```shell
# Send a flare
rekki flare

# Send a flare with some additional context
rekki flare -- I am trying to deploy my project but it fails. Can you help?
```

### `rekki help`

> Help about any command or topic.

Get more information about any command or topic in the CLI. Execute `rekki
help` without arguments to see all the available commands and topics.

#### Usage

```
rekki help [command|topic]
```

#### Examples

```shell
# main help page
rekki help

# help for the run command
rekki help run

# help for the options topic
rekki help options
```

### `rekki version`

> Print the version.

Print the git sha1 of the commit used to build this rekki-cli, followed by a
newline.

#### Usage

```
rekki version
```

#### Examples

```shell
# Print the rekki-cli version
rekki version
```

## Topics

### Feedbacks & Issues

You can get in touch with the Platform Team in the
[#platform-public](https://rekkiapp.slack.com/archives/CBJHYNGEL) channel for
any feedback, issue or suggestion that you might have.

### Options & Environment

The following options can be passed to any command:

```
-c, --cluster string         the cluster you want to interact with (default "eu-west-2")
-h, --help                   print the help
-i, --identity-file string   an SSH private key used for public key authentication
-n, --namespace string       the kubernetes namespace for this command (default "feat")
    --no-color               force color output to be disabled
```

Additionally, the following environment variables are supported:

| Key                          | Value                                                 |
| ---------------------------- | ----------------------------------------------------- |
| `DEBUG`                      | set to `"true"` to enable debug information on stderr |
| `NO_COLOR`                   | set to any value to disable color output              |
| `REKKI_CLI_NO_COLOR`         | set to any value to disable color output              |
| `REKKI_CLI_NO_REPORTING`     | set to any value to disable slack error reporting     |
| `REKKI_CLI_NO_VERSION_CHECK` | set to any value to disable the remote version check  |
| `REKKI_CLI_STACKTRACE`       | set to any value to enable stacktraces                |

Options take precedence when they conflict with environment variables.

### Resources

A resource represents the concept of a remote resource available in the cluster
or infrastructure. It is in various commands accross the CLI.

The full syntax for a resource is:

    [localPort:][kind/]name[@namespace][:remotePort]

The syntax is actually quite permissive, when the values are omitted then the
defaults are as follow:

- `localPort`: random for `rekki run` tunnels, deterministic for `rekki tunnel`, `0` otherwise
- `kind`: `service` by default
- `namespace`: the command namespace (from `-n` or `--namespace`) is used by default
- `remotePort`: asking the Kubernetes API for `rekki run` and `rekki tunnel` tunnels, `0` otherwise

The different kinds are:

- `bastion`: for our bastion instance
- `database`: for our AWS RDS instances (alias: `db`, `pg`, `postgre`, `postgres`, `postgresql`, `rds`)
- `deployment`: for Kubernetes deployments (alias: `deploy`)
- `job`: for Kubernetes jobs
- `pod`: for Kubernetes pods
- `redis`: for our AWS Elasticache instances
- `replicaset`: for Kubernetes replica sets (alias: `rs`)
- `service`: for Kubernetes services (alias: `svc`)

Special case for `bastion`, `database` and `redis`: the 3 of them can be used
as names (even though they are technically kinds). That means you can do the
following: `rk tunnel db`. The proper name will be inferred based on the
namespace. This is especially useful for the feat database or the redis
instances, where the names are hard to remember or generated dynamically.

Resources are used in different locations. Here is a non-exhaustive list of
**valid** examples:

- `rekki delete job/notemailer`
- `rekki env svc/hulk@live`
- `rekki history hulk`
- `rekki logs svc/hulk`
- `rekki run -t marketplace-everything@local:9090 -t blackrock-search-grpc@live`
- `rekki run -t svc/marketplace-everything@local:9090 -t svc/blackrock-search-grpc@live`
- `rekki ssh bastion`
- `rekki tunnel db/live`
- `rekki tunnel db@live`
- `rekki tunnel db`
- `rekki tunnel hulk`
- `rekki tunnel svc/hulk@live`
- `rekki tunnel svc/hulk`

### Services & Jobs

Services are long running processes that handle HTTP requests.

Jobs are short running processes that perform computing tasks.
