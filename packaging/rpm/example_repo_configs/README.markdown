### Example Repository Configurations

The repository configuration files in this directory provide examples
of the configurations required for installing OpenDaylight from the CentOS
Community Build System, where its source RPM (via `../build.sh`) is built
in a standard environment and hosted for distribution.

These repository configurations tell your package manager, like `yum`,
the details required for installing OpenDaylight from the CBS.

We will eventually use the `-testing-`, `-canidate-` and `-release-` tags to
control the verbosity of our updates (infrequent stable releases vs frequent
CI/CD/CR). For now, we are just using the `-canidate-` tag.

We will also eventually sign our RPMs, at which point we will enable GPG
checks via the `gpgcheck` repo config variable.
