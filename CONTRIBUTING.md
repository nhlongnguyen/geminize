# Contributing to Geminize

First of all, thank you for considering contributing to Geminize! It's people like you that make Geminize better for everyone.

## Code of Conduct

This project and everyone participating in it is governed by the [Geminize Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [nhatlongnguyen1992@gmail.com](mailto:nhatlongnguyen1992@gmail.com).

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report. Following these guidelines helps maintainers understand your report, reproduce the behavior, and fix the issue.

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps which reproduce the problem** in as many details as possible.
- **Provide specific examples to demonstrate the steps** such as code snippets or links to your implementation.
- **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
- **Explain which behavior you expected to see instead and why.**
- **Include screenshots or animated GIFs** which show you following the described steps and clearly demonstrate the problem.
- **If the problem is related to performance or memory usage**, include a profiling report if possible.
- **If the problem wasn't triggered by a specific action**, describe what you were doing before the problem happened.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.

- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
- **Provide specific examples to demonstrate the steps** if applicable.
- **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
- **Explain why this enhancement would be useful** to most Geminize users.

### Pull Requests

- Fill in the required template
- Do not include issue numbers in the PR title
- Include screenshots and animated GIFs in your pull request whenever possible
- Follow the Ruby style guide (see below)
- Include tests for new functionality
- Document new code

## Development Environment Setup

1. Fork the repo
2. Clone your fork: `git clone https://github.com/your-username/geminize.git`
3. Change to the project directory: `cd geminize`
4. Install dependencies: `bundle install`
5. Run the tests: `bundle exec rake spec`

## Ruby Style Guide

We use [StandardRB](https://github.com/standardrb/standard) for code styling. Before submitting a PR, please run:

```bash
bundle exec standardrb --fix
```

## Testing

We use RSpec for testing. Please ensure all your code is tested:

```bash
bundle exec rspec
```

For comprehensive testing with VCR cassettes (which record API calls), ensure to set up a valid `GEMINI_API_KEY` in your environment or in a `.env` file.

## Documentation

We use YARD for documentation. Please document all public methods and classes using YARD syntax:

```ruby
# This method does something useful
#
# @param name [String] The name to use
# @param options [Hash] Additional options
# @option options [Boolean] :recursive Whether to recursively process
# @return [Array<String>] A list of processed results
def some_method(name, options = {})
  # ...
end
```

## Versioning

We follow [Semantic Versioning](https://semver.org/). In short:

- MAJOR version for incompatible API changes
- MINOR version for added functionality in a backwards-compatible manner
- PATCH version for backwards-compatible bug fixes

## Releasing

Only maintainers can create releases. The process is:

1. Update version in `lib/geminize/version.rb`
2. Update `CHANGELOG.md` with changes since last release
3. Commit: `git commit -am "Prepare for release vX.Y.Z"`
4. Create tag: `git tag -a vX.Y.Z -m "Version X.Y.Z"`
5. Push: `git push && git push --tags`
6. Create a new release on GitHub
7. Build and push the gem: `bundle exec rake release`

## Questions or Need Help?

Feel free to reach out via the GitHub Discussions on this project or by email.

Again, thank you for your interest in contributing to Geminize!
