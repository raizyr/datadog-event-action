# DataDog Events - GitHub Action

A GitHub Action that triggers DataDog Events.

## Credit

Originally based on [Glennmen/datadog-event-action](https://github.com/Glennmen/datadog-event-action) :heart:

## Usage

```
- name: DataDog Event
  uses: raizyr/datadog-event-action@1.0.0
  with:
    datadog_api_key: ${{ secrets.DD_API_KEY }}
    title: Build Succeeded
    text: We did it! 🎉
    priority: (Can be one of normal or low. Default: normal)
    tags: (optional)
    alert_type: (Can be one of error, warning, info, or success. Default: info)
    datadog_us: false
```

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `datadog_api_key` | Your DataDog API key | true | |
| `datadog_us` | Send events to the US endpoint instead of EU endpoint | false | false |
| `title` | The title of the event | true | |
| `text` | The text of the event | true | |
| `use_markdown` | Use markdown in the event text | false | true |
| `priority` | The priority of the event | false | normal |
| `tags` | Event tags as a JSON array eg. `event_tags: '["app:test","env:production"]'` | false | |
| `alert_type` | The alert type of the event | false | info |
| `aggregation_key` | The aggregation key of the event | false | |
| `date_happened` | The date the event happened | false | Uses calculated action start timestamp |
| `device_name` | The device name of the event | false | |
| `host` | The host of the event | false | |
| `related_event_id` | The ID of the event to which this event is related | false | |
| `dry_run` | Dry run mode, does not send the event | false | false |

## Outputs

| Output | Description |
| --- | --- |
| `event_id` | The ID of the event that was created |
| `event_url` | The URL of the event that was created |
| `json` | The JSON response from the DataDog API |

