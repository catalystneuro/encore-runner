# encore-runner

This repository runs [Encore](https://encorescience.org) attempts and sends the results to the Encore registry, [encorescience/encore-registry](https://github.com/encorescience/encore-registry). CatalystNeuro runs its own attempts from here, and another organization can fork it to run attempts with its own Anthropic API key, in its own GitHub account.

The protocol itself lives in [encorescience/encore-protocol](https://github.com/encorescience/encore-protocol); this repository only calls it. How a run reaches the registry, and what the registry checks before it takes one, is described in encore-protocol's `docs/outside-runs.md`.

## Running a Paper

An attempt on a paper begins with three kinds of run, each started from the Actions tab with the **Run** workflow, giving the paper's key in the registry (its `papers/keys.yaml`, such as `smith-2020`) and the role:

1. **claims**: the reader writes the paper's claims file.
2. **claims-check**: a second reader checks the claims file and corrects it. Run it again until its last check says the file is ready.
3. **author**: the author's attempt to reproduce the claims from the data.

Each run starts from where the last one left the attempt in the registry, on its branch `attempt/<paper>`, so start a run only after the registry has taken the one before. When the registry already has checked claims for the paper on its main branch, start with the author. After the author's run, the registry takes the attempt over: its verification rounds, the author's revisions after them and the recorder run there, as for any attempt, and a person at CatalystNeuro merges it.

At the end of each run, the `deliver` job sends it to the registry. In encorescience/encore-runner it starts the registry's intake and waits for it, so the run fails if the registry does not take it. In a fork, the run's summary has a link to an "Outside run" issue on the registry with the run's address filled in. Open it; someone at CatalystNeuro approves the run, and the intake commits it to the attempt's branch, comments on the issue and closes it.

## Setting Up a Fork

Fork this repository into your organization's GitHub account and enable Actions on the fork. The fork is public, as a fork of a public repository is; it holds no papers and no keys. Then, under the fork's settings:

1. Add a repository secret `ANTHROPIC_API_KEY` with your organization's key. Runs are billed to it.
2. Add an environment named `papers` with a secret `PAPERS_DEPLOY_KEY`: the private half of a read-only deploy key on your own paper store, a private repository that holds the papers' text and PDFs. encore-protocol's `docs/outside-runs.md` says how to lay it out. The runs read the papers in that environment and never commit them.
3. Add a repository variable `ENCORE_PAPERS_REPO` with the paper store's name, as `owner/name`.
4. Add a repository variable `ENCORE_ACCOUNTABLE` with the name the attempt records as accountable for it, for example "Acme Lab, University of Somewhere". Without it the record names the fork's owner.

A paper the registry does not list yet has to be added there first; ask for it with an issue on the registry.

## Encore's Own Runs

encorescience/encore-runner is set up the same way, with CatalystNeuro's Claude account (the secret `CLAUDE_CODE_OAUTH_TOKEN`) in place of an API key, CatalystNeuro's paper store, and one more secret, `ENCORE_INTAKE_TOKEN`: a token that may start workflows in encorescience/encore-registry, so that its runs reach the intake by themselves. The registry takes its runs as soon as they pass the intake's checks, without waiting for a person.
