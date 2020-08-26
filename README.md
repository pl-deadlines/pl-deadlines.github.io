# Programming Languages Conferences Deadlines Countdown

## Adding/updating an event

Add an entry to `events.json`, the record must be of the following form, and must either be added to the conferences list or the workshops list.

```
	{
		"name": "ACM SIGPLAN Symposium on Principles of Programming Languages",
		"abbrv": "POPL",
		"year": "2021",
		"url": "https://popl21.sigplan.org",
		"date": "Sun 17 - Fri 22 Jan 2021",
		"location": "Copenhagen, Denmark",
		"deadline": "2020-07-09T23:59:59-12:00",
		"tags": ["Compilation"],
		"notes": "May take place online instead, because of the COVID-19 situation."
	}
```

Descriptions of the fields:

| Field name    | Description                                                 |
|---------------|-------------------------------------------------------------|
| `name`        | Name of the event                                           |
| `abbrv`       | Abbreviated name of the event, e.g., POPL, ICFP, etc        |
| `year`        | Which year is the event happening                           |
| `url`         | URL to the event home page                                  |
| `date`        | When the event is happening                                 |
| `location`    | Where the event is happening                                |
| `deadline`    | Deadline                                                    |
| `tags`        | One or multiple tags                                        |
| `notes`       | Additional notes about the event                            |

When adding tags, please make sure that it is one of the tags enumerated at the beginning of the file.

The deadline must be written in the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, i.e., `YYYY-MM-DDThh:mm:ss±xx:yy` where `xx:yy` represents the time offset from UTC. The Anywhere on Earth (AoE) timezone corresponds to `-12:00`.
