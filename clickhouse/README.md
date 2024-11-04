This folder contains Clickhouse configurations to optimise the performance of the database. You can apply them by mounting the files to the corresponding locations in the Clickhouse container depending on your needs.

## disable-user-logging.xml

This configuration disables user-specific logging in Clickhouse (see [Calming down Clickhouse - Stop logging queries](https://theorangeone.net/posts/calming-down-clickhouse/#stop-logging-queries)). 

## reduce-logs.xml

This configuration disables all logging in Clickhouse (see [Calming down Clickhouse - Reduce logging](https://theorangeone.net/posts/calming-down-clickhouse/#reduce-logging)) and only logs warnings (or higher) to the console.

## preserve-ram-config.xml / preserve-ram-user.xml

These configurations are aimed to reduce the RAM usage on Clickhouse database, to around 250-500 MB depending on the usage.

- `preserve-ram-config.xml` is applied to the server-wide settings.
- `preserve-ram-user.xml` is applied to the default user profile.

It's a good starting point for smaller sites (<1M total events), in case you hit that limit you might need to adjust the settings.
