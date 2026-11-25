# encore-runner

This repository runs [Encore](https://encorescience.org) attempts and sends the results to the Encore registry, [encorescience/encore-registry](https://github.com/encorescience/encore-registry). CatalystNeuro runs its own attempts from here, and another organization can fork it to run attempts with its own Anthropic API key, in its own GitHub account.

The protocol itself lives in [encorescience/encore-protocol](https://github.com/encorescience/encore-protocol); this repository only calls it. How an attempt reaches the registry, and what the registry checks before it takes one, is described in encore-protocol's `docs/outside-runs.md`.

## Running a Paper

Start the **Attempt** workflow from the Actions tab, giving the paper's key in the registry (its `papers/keys.yaml`, such as `smith-2020`). One run of the workflow makes the whole attempt:

1. It tells the registry that this repository has started an attempt on the paper.
2. It runs every step in order: the reader's **claims** and the **claims-check**, the **author**, two verification rounds each followed by the author's revision, a third round when the second revision proposed changes, the **reconcile** run when the paper has an earlier attempt, and the **recorder**'s notes.
3. It sends the finished attempt to the registry.

The runs read the registry and write nothing to it. Between runs the attempt's state is on this repository's own branch `attempt/<paper>`: the paper's claims, record, entry and transcripts, and a ledger of the runs. Each run is signed, and the registry checks every signature, and that each run started from what the one before it left, before it takes the attempt. encore-protocol's `docs/outside-runs.md` describes the checks.

When a step fails, the attempt stops and its branch stays as the last step left it. To go on, start **Attempt** again with the role to go on from in `from`, such as `verifier-1`. The **Run** workflow makes one role at a time, and **Send** sends a finished attempt whose last steps were made that way. When the registry already has checked claims for the paper on its main branch, start from `author`.

How the two notices reach the registry depends on the repository. In encorescience/encore-runner the workflow starts the registry's intake itself and waits for it, so it fails if the registry refuses. In a fork, the run's summary has a link to an "Outside attempt" issue on the registry with the run's address and the paper filled in, once at the start and once at the end. Open each; someone at CatalystNeuro approves it, and the registry's intake comments on the issue and closes it. The attempt does not wait for the first of them.

After the registry has taken the attempt, its usual check runs on the attempt's pull request and a person at CatalystNeuro merges it.

## Setting Up a Fork

Fork this repository into your organization's GitHub account and enable Actions on the fork. The fork is public, as a fork of a public repository is; it holds no papers and no keys. Then, under the fork's settings:

1. Add a repository secret with your organization's account for Claude: `ANTHROPIC_API_KEY`, an API key whose runs are billed to it, or `CLAUDE_CODE_OAUTH_TOKEN`, a Claude subscription's token from `claude setup-token`, whose runs count against the subscription's limits.
2. Add a repository secret `PAPERS_DEPLOY_KEY`: the private half of a read-only deploy key on your own paper store, a private repository that holds the papers' text and PDFs. encore-protocol's `docs/outside-runs.md` says how to lay it out. It has to be a repository secret: an environment's secrets do not reach the protocol's workflows from another organization. Add an environment named `papers` too; the runs read the papers in it and never commit them.
3. Add a repository variable `ENCORE_PAPERS_REPO` with the paper store's name, as `owner/name`.
4. Add a repository variable `ENCORE_ACCOUNTABLE` with the name the attempt records as accountable for it, for example "Acme Lab, University of Somewhere". Without it the record names the fork's owner.

A paper the registry does not list yet has to be added there first; ask for it with an issue on the registry.

## Encore's Own Runs

encorescience/encore-runner is set up the same way, with CatalystNeuro's Claude accounts (the secrets `CLAUDE_CODE_OAUTH_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN_UNVERIFIED` and `ANTHROPIC_API_KEY_CREDITS`, chosen with the input `account`), CatalystNeuro's paper store, and one more secret, `ENCORE_INTAKE_TOKEN`: a token that may start workflows in encorescience/encore-registry, so that its notices reach the intake by themselves. The registry takes its attempts as soon as they pass the intake's checks, without waiting for a person.
