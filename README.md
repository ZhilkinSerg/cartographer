# Cartographer

The sleek web-app incarnation of the [CDDA](http://en.cataclysmdda.com/) [overmapper](https://github.com/drbig/catatools#overmapperrb) tools.

**Status**: Consider alpha. It works, usually.

Things missing:

  - Some way to better handle the upload. CDDA map files tend to get very huge very fast. But then accepting common archives (like `zip`) is a can of worms
  - Similarly the generated maps tend to be in megabytes (no problem if space and bandwidth aren't an issue of course)
  - It doesn't actually clean old maps at all
  - General robustness, error handling and reporting

On the bright side the mapper is *fast*, being very close to a native x86_64 build of the Go version (profiling and streaming JSON parsers do wonders for performance improvements).

![Cartographer thumbnail](http://i.imgur.com/oPqdqaF.png)

You should be able to find the currently running instance at the [CDDA Web Tools Directory](http://tools.cataclysmdda.com/).

## Setup

You'll need a working [Beanstalk](http://kr.github.io/beanstalkd/) daemon and `terrain.dat`, which you can generate using the [overmapper-2.rb](https://github.com/drbig/catatools/blob/master/overmapper-2.rb) (yes, this is alpha and this functionality hasn't been imported here yet).

```bash
$ git clone https://github.com/drbig/cartographer.git
$ cd cartographer
$ $EDITOR .env
$ bundle install
$ rake assets:all
$ foreman start
```

## Contributing

Follow the usual GitHub workflow:

 1. Fork the repository
 2. Make a new branch for your changes
 3. Work (and remember to commit with decent messages)
 4. Push your feature branch to your origin
 5. Make a Pull Request on GitHub

## Licensing

Standard two-clause BSD license, see LICENSE.txt for details.

Copyright (c) 2015 Piotr S. Staszewski
