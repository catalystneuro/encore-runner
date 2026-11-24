# encore-runner

This repository runs [Encore](https://encorescience.org) attempts and sends the results to the Encore registry, [encorescience/encore-registry](https://github.com/encorescience/encore-registry). CatalystNeuro runs its own attempts from here, and another organization can fork it to run attempts with its own Anthropic API key, in its own GitHub account.

The protocol itself lives in [encorescience/encore-protocol](https://github.com/encorescience/encore-protocol); this repository only calls it. How a run reaches the registry, and what the registry checks before it takes one, is described in encore-protocol's `docs/outside-runs.md`.
