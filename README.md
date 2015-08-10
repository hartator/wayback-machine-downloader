# Wayback Machine Downloader

Download any website from the Internet Archive Wayback Machine.

## Installation

You need to install Ruby on your system - if you don't already have it, then run:

    gem install wayback_machine_downloader

## Usage 

### Basic

Run wayback_machine_downloader with the base url of the website you want to retrieve as a parameter:

    wayback_machine_downloader http://example.com

### How it works

It will download the last version of every file present on Wayback Machine to `websites/example.com/`. It will also re-create a directory structure and auto-create `index.html` pages to work seamlessly with Apache and Nginx. URLs and links structure are preserved as much as possible.

## Optional Timestamp

You may want to supply a specific timestamp to lock your backup to an older version of the website. Wayback Machine Downloader will then fetch only file versions on or prior to the timestamp specified:

    wayback_machine_downloader http://example.com` --timestamp 20060716231334

### Contributing

Contributions are welcome! Just submit a pull request via GitHub.

To run the tests:

    rake test
