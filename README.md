# Git Utils

<p>
    <a href="https://github.com/tbidne/git-utils/workflows/stack%20build/badge.svg?branch=master" alt="stack build">
        <img src="https://img.shields.io/github/workflow/status/tbidne/git-utils/stack build/master?logo=haskell&style=plastic" height="20"/>
    </a>
    <a href="https://github.com/tbidne/git-utils/workflows/docker%20push/badge.svg?branch=master" alt="docker hub">
        <img src="https://img.shields.io/github/workflow/status/tbidne/git-utils/docker push/master?logo=docker&logoColor=white&style=plastic" height="20"/>
    </a>
    <a href="https://hub.docker.com/repository/docker/tbidne/git-utils" alt="docker hub">
        <img src="https://img.shields.io/static/v1?label=docker&message=hub&color=089cec&style=plastic&logo=docker&logoColor=white" height="20"/>
    </a>
</p>

This application provides a wrapper for `git` CLI actions. Two commands are currently supported:

- Fast Forward: Fast forwards all local branches (`--ff-only`) on `upstream`, `origin/master`, or a provided branch name.

- Find Stale: Displays branches that are considered "stale", based on the date of the last commit (default threshold is 30 days).

For more explicit usage see the various help pages:

- `git-utils --help`
- `git-utils fast-forward --help`
- `git-utils find-stale --help`

## Building with Stack

To build in the current directory run `stack build`. Then run with:

```shell
stack exec git-utils -- [CMD] [OPTIONS]
```

If you instead wish to build to a global location (e.g. `~/.local/bin`) run `stack install`. Then:

```shell
git-utils [CMD] [OPTIONS]
```

## Docker


A docker image can be downloaded with `docker pull tbidne/git-utils:latest`.

It can also be built manually, e.g.

```docker
Docker build .
```

To run you must mount your local filesystem with `-v` and provide the mapped directory as a path argument, e.g.,

```docker
docker run -v /path/to/dir:/share --rm <image> [CMD] --path=/share [OPTIONS]
```

Note: `fast-forward` is not supported with docker because it fetches from a remote. Not only would this require mounting real `git` credentials to the image, it would require the remote being in the image's `known_hosts`.

**IMPORTANT**: if you are on a mac then you will want to use the `cached` flag, e.g.

```docker
docker run -v /path/to/dir:/share:cached --rm <image> find-stale --limit=30 --path=share
```

The default docker volume mounting for mac has terrible performance, so docker has mitigated this by providing volume options. The options most likely to help are `cached` and `delegated`.

See [here](https://docs.docker.com/docker-for-mac/osxfs-caching/) for more info.
