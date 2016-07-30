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

## From Timestamp

Optional. You may want to supply a from timestamp to lock your backup to a specific version of the website. Timestamps can be found inside the urls of the regular Wayback Machine website (e.g., http://web.archive.org/web/*20060716231334*/http://example.com). You can also use years (2006), years + month (200607), etc. Can be used in combination of *To Timestamp*.
Wayback Machine Downloader will then fetch only file versions on or after the timestamp specified:

    wayback_machine_downloader http://example.com --from 20060716231334

## To Timestamp

Optional. You may want to supply a to timestamp to lock your backup to a specifc version of the website. Timestamps can be found inside the urls of the regular Wayback Machine website (e.g., http://web.archive.org/web/*20100916231334*/http://example.com). You can also use years (2010), years + month (201009), etc. Can be used in combination of *From Timestamp*.
Wayback Machine Downloader will then fetch only file versions on or before the timestamp specified:

    wayback_machine_downloader http://example.com --to 20100916231334

## Only URL Filter

Optional. You may want to retrieve files which are of a certain type (e.g., .pdf, .jpg, .wrd...) or are in a specific directory. To do so, you can supply the `--only` flag with a string or a regex (using the '/regex/' notation) to limit which files Wayback Machine Downloader will download.

For example, if you only want to download files inside a specific `my_directory`:

    wayback_machine_downloader http://example.com --only my_directory
    
Or if you want to download every images without anything else:
    
    wayback_machine_downloader http://example.com --only "/\.(gif|jpg|jpeg)$/i"

## Exclude URL Filter

Optional. You may want to retrieve files which aren't of a certain type (e.g., .pdf, .jpg, .wrd...) or aren't in a specific directory. To do so, you can supply the `--exclude` flag with a string or a regex (using the '/regex/' notation) to limit which files Wayback Machine Downloader will download.

For example, if you want to avoid downloading files inside `my_directory`:

    wayback_machine_downloader http://example.com --exclude my_directory
    
Or if you want to download everything except images:
    
    wayback_machine_downloader http://example.com --exclude "/\.(gif|jpg|jpeg)$/i"

## Using the Docker image

As an alternative installation way, we have a Docker image! Retrieve the wayback-machine-downloader Docker image this way:

    docker pull hartator/wayback-machine-downloader

Then, you should be able to use the Docker image to download websites. For example:

    docker run --rm -it -v $PWD/websites:/websites hartator/wayback-machine-downloader http://example.com

## Contributing

Contributions are welcome! Just submit a pull request via GitHub.

To run the tests:

    bundle install
    bundle exec rake test
