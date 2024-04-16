### Description:

<!--
This should be a brief one or two line description of the PR. Details should be contained in commit messages.
-->

### Special Notes:

<!-- This section and header can be removed if not required.

Examples of special notes that must be included in the PR:
- If this is a hotfix for production, which needs to be deployed after merging
- If this requires manual work to deploy the PR, e.g. a parameter change
- If this has associated internal documentation too
-->

---

### Submitter:

Have you:

* [ ] Labelled this PR, e.g. `bug`, `deployment`, `enhancement` ...etc.

- A `deployment` can be reviewed, and merged, by a single reviewer.
- It can only be used to deploy, change, or remove clusters based on existing patterns for staging.
- Anything involving prod, or production facing services must use the normal 2 person review.
- All other PR types require the usual PR process (e.g. 2 person).

---

### Reviewer

Have you:

* [ ] Verified this PR uses the correct label(s) based on the rules above?
* [ ] Checked if this could affect production (e.g. a global value that's changed without an override)?
* [ ] Tested setting this up, if it's not a deployment, to verify it can be redeployed with any documentation if appropriate?
