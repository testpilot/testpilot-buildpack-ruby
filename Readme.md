# TestPilot BuildPack/Ruby

This is a TestPilot BuildPack for Ruby, Rails 2.x, and Rails 3.x. It is based on the [Heroku Ruby Buildpack](https://github.com/heroku/heroku-buildpack-ruby) but customised for the unique build environment provided by TestPilot.

## Flow

TestPilot loads the latest version of the build pack from Github before every test run, because of our heavy use of TDD we are able to live on the edge and provide community contributed fixes and updates to this build pack with almost no turnaround time.

1. When a new test is dispatched, TestPilot will checkout the latest code for your project into a dedicated working directory.
2. We then run the `detect` binary from all available BuildPacks until one which can support your project is detected.
3. After this we run the `compile` binary for the detected build pack and configure the environment which runs your tests.
4. Once the environment is configured, including setting up databases, installing gems, and caching, we run your build pipeline as configured within TestPilot or the `.testpilot.yml` configuration file.

