# PlayTheWheels App for iOS
Main iOS app which detect rotation, make sounds and control LED via [ptw-wheel](https://github.com/karappo/ptw-wheel).

## Requirements

- Ruby
- [cocoapods](https://cocoapods.org/)

## Recommends

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

## Licenses

All source code by [Karappo Inc.](http://karappo.net) (except [these sound files](https://github.com/karappo/PlayTheWheels/tree/master/PlayTheWheels/assets/tones)) are released under the [MIT license](https://raw.githubusercontent.com/karappo/PlayTheWheels/master/LICENSE.txt).

[These sound files](https://github.com/karappo/PlayTheWheels/tree/master/PlayTheWheels/assets/tones) by [Kosuke Anamizu](http://kosukeanamizu.com/) & [Tokuro Oka](http://www.lifetones.net/) are released under the [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a>
