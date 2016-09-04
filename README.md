# Wayback Machine Downloader

Download an entire website from the Internet Archive Wayback Machine.

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

## Advanced Usage

    Usage: wayback_machine_downloader http://example.com

    Download an entire website from the Wayback Machine.

    Optional options:
        -f, --from TIMESTAMP             Only files on or after timestamp supplied (ie. 20060716231334)
        -t, --to TIMESTAMP               Only files on or before timestamp supplied (ie. 20100916231334)
        -o, --only ONLY_FILTER           Restrict downloading to urls that match this filter (use // notation for the filter to be treated as a regex)
        -x, --exclude EXCLUDE_FILTER     Skip downloading of urls that match this filter (use // notation for the filter to be treated as a regex)
        -a, --all                        Expand downloading to error files (40x and 50x) and redirections (30x)
     	-l, --list                       Only list file urls in a JSON format with the archived timestamps. Won't download anything.
            --threads NUMBER             Number of threads to use while downloading website (ie. 20)
        -v, --version                    Display version

## From Timestamp

    -f, --from TIMESTAMP

Optional. You may want to supply a from timestamp to lock your backup to a specific version of the website. Timestamps can be found inside the urls of the regular Wayback Machine website (e.g., http://web.archive.org/web/20060716231334/http://example.com). You can also use years (2006), years + month (200607), etc. It can be used in combination of To Timestamp.
Wayback Machine Downloader will then fetch only file versions on or after the timestamp specified.

Example:

    wayback_machine_downloader http://example.com --from 20060716231334

## To Timestamp

    -t, --to TIMESTAMP

Optional. You may want to supply a to timestamp to lock your backup to a specifc version of the website. Timestamps can be found inside the urls of the regular Wayback Machine website (e.g., http://web.archive.org/web/20100916231334/http://example.com). You can also use years (2010), years + month (201009), etc. It can be used in combination of From Timestamp.
Wayback Machine Downloader will then fetch only file versions on or before the timestamp specified.

Example:

    wayback_machine_downloader http://example.com --to 20100916231334

## Only URL Filter

     -o, --only ONLY_FILTER

Optional. You may want to retrieve files which are of a certain type (e.g., .pdf, .jpg, .wrd...) or are in a specific directory. To do so, you can supply the `--only` flag with a string or a regex (using the '/regex/' notation) to limit which files Wayback Machine Downloader will download.

For example, if you only want to download files inside a specific `my_directory`:

    wayback_machine_downloader http://example.com --only my_directory

Or if you want to download every images without anything else:

    wayback_machine_downloader http://example.com --only "/\.(gif|jpg|jpeg)$/i"

## Exclude URL Filter

     -x, --exclude EXCLUDE_FILTER

Optional. You may want to retrieve files which aren't of a certain type (e.g., .pdf, .jpg, .wrd...) or aren't in a specific directory. To do so, you can supply the `--exclude` flag with a string or a regex (using the '/regex/' notation) to limit which files Wayback Machine Downloader will download.

For example, if you want to avoid downloading files inside `my_directory`:

    wayback_machine_downloader http://example.com --exclude my_directory

Or if you want to download everything except images:

    wayback_machine_downloader http://example.com --exclude "/\.(gif|jpg|jpeg)$/i"

## Expand downloading to all file types

     -a, --all

Optional. By default, Wayback Machine Downloader limits itself to files that responded with 200 OK code. If you also need errors files (40x and 50x codes) or redirections files (30x codes), you can use the `--all` or `-a` flag and Wayback Machine Downloader will download them in addition of the 200 OK files. It will also keep empty files that are removed by default.

Example:

    wayback_machine_downloader http://example.com --all

## Only list files without downloading

     -l, --list

It will just display the files to be downloaded with their snapshot timestamps and urls. The output format is JSON. It won't download anything. It's useful for debugging or to connect to another application.

Example:

    wayback_machine_downloader http://example.com --list

## Download using ruby green threads

    --threads NUMBER

Optional. Default is 1. Number of threads to use while downloading website.

Example:

    wayback_machine_downloader http://example.com --threads 20

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

## Donation

Wayback Machine Downloader is free and open source.

If you want to donate: [![Gratipay Team](https://img.shields.io/gratipay/team/hartator.svg)](https://gratipay.com/hartator/)

You can also donate to the Archive.org: https://archive.org/donate/
