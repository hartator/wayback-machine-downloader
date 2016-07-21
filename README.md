# Wayback Machine Downloader

Download any website from the Internet Archive Wayback Machine.

## Installation

You need to install Ruby on your system (>= 1.9.2) - if you don't already have it.
Then run:

    gem install wayback_machine_downloader

**Tip:** If you run into permission errors, you might have to add `sudo` in front of this command.

## Basic Usage

Run wayback_machine_downloader with the base url of the website you want to retrieve as a parameter (e.g., http://example.com):

    wayback_machine_downloader http://example.com

## How it works

It will download the last version of every file present on Wayback Machine to `./websites/example.com/`. It will also re-create a directory structure and auto-create `index.html` pages to work seamlessly with Apache and Nginx. All files downloaded are the original ones and not Wayback Machine rewritten versions. This way, URLs and links structure are the same than before.

## Optional Timestamp

You may want to supply a specific timestamp to lock your backup to an older version of the website, which can be found inside the urls of the regular Wayback Machine website (e.g., http://web.archive.org/web/20060716231334/http://example.com).
Wayback Machine Downloader will then fetch only file versions on or prior to the timestamp specified:

    wayback_machine_downloader http://example.com --timestamp 20060716231334

## Optional Only URL Filter

You may want to retrieve files which are of a certain type (e.g., .pdf, .jpg, .wrd...) or are in a specific directory. To do so, you can supply the `--only` flag with a string or a regex (using the '/regex/' notation) to limit which files Wayback Machine Downloader will download.

For example, if you only want to download files inside a specific `my_directory`:

    wayback_machine_downloader http://example.com --only my_directory
    
Or if you want to download every images without anything else:
    
    wayback_machine_downloader http://example.com --only "/\.(gif|jpg|jpeg)$/i"

## Using the Docker images

All the options should work the same, just run it with this command instead of installing the gem:

    docker run --rm -it -v $PWD/websites:/websites hartator/wayback-machine-downloader

You can use git branches as image tags to test new features on Docker Hub automated builds:

    docker run --rm -it -v $PWD/websites:/websites yourname/yourrepo:yourfeature

## Contributing

Contributions are welcome! Just submit a pull request via GitHub.

To run the tests:

    bundle install
    bundle exec rake test
