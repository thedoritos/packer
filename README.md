# Packer - Pack your configuration

## Quick Start

Clone this repository and run unpack.

```sh
$ cd path/to/this/repository

$ ruby packer.rb unpack develop
# Password: sample

$ ruby packer.rb unpack release
# Password: sample

$ ls sample
# => Secrets.swift config
```

## Why Packer?

When I develop an app, I want to define multiple environments such as `develop`, `staging`, `qa`, `release`.
And there may be configuration files for each environments.

I usually list these files in `.gitignore` to exclude these from Git repository because these contains information like SDK token, API key, and etc.
But this approach makes it more complicated to switch environments.
I have to remember which files to be switched and do it by hand.

Using `Packer`,

- :memo: I can list config files grouped by environment in single `Packerfile`.
- :robot: I can switch environment by commands `pack` & `unpack`.
- :closed_lock_with_key: The files are packed into an encrypted file so that I can commit it to Git repository.

## Creating Pack Yourself

Copy `packer.rb` to your project root.

### Define Packerfile

Define your configurations and list files you need.

```yml
develop: &base
  - sample/Secrets.swift
  - sample/config/secrets.xcconfig

release:
  - *base
  - sample/config/PackerService-Info.plist
```

You can use YAML notation. Note that Packer flattens array when it reads Packerfile.

### Pack your configuration

You can run `pack {configuration}` to pack your files into `Packs/{configuration}.pack`.

```sh
$ ruby packer.rb pack develop
# Password: YourPw4Develop

$ ruby packer.rb pack release
# Password: YourPw4Release

$ ls ./Packs
# => develop.pack release.pack
```

### Set Up gitignore

Packer creates `.packer` directory which is only for tmp working use.
It is recommended to add this into your `.gitignore`.

```sh
$ echo '/.packer' >> .gitignore
```

Packer deletes tmp files when it successfully exit process.
But if it is terminated by error or other reasons, the files may be remained.
And they may be accidentally commited to Git repo.

## Developer

https://github.com/thedoritos
