# PlayTheWheels App for iOS

This project operate with Arduino Project [ptw-wheel](https://github.com/karappo/ptw-wheel).

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
