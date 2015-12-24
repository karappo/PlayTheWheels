# PlayTheWheels App for iOS
Main iOS app which detect rotation, make sounds and control LED via [ptw-wheel](https://github.com/karappo/ptw-wheel).

## Requirements

- Ruby
- [cocoapods](https://cocoapods.org/)

## Recomends

- [rbenv](https://cocoapods.org/)
- [bundler](https://cocoapods.org/)

## Install libraries

```sh
# install ruby with rbenv
rbenv install 2.1.2
rbenv rehash

# install bundler
rbenv exec gem install bundler

# install cocoapods
rbenv exec bundle install --path=vendor/bundle --binstubs=vendor/bin

# install libraries with cocoapods
rbenv exec bundle exec pod install

```

## License

Copyright (c) 2015 Karappo Inc.

All source code except [these sound files](fileshttps://github.com/karappo/PlayTheWheels/tree/master/PlayTheWheels/assets/tones) are released under the MIT license

https://raw.githubusercontent.com/karappo/PlayTheWheels/master/LICENSE.txt