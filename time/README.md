# Time and Timezone Tool

This tool wraps the official MCP Time server to provide comprehensive time and timezone conversion capabilities within the Language Operator ecosystem.

## Overview

The Time tool enables agents to work with time across different timezones using IANA timezone names, with automatic system timezone detection for seamless time operations.

## Features

- **Current time queries**: Get current time in any timezone
- **Timezone conversions**: Convert time between different timezones  
- **IANA timezone support**: Full support for standard timezone names
- **DST awareness**: Automatic daylight saving time handling
- **System timezone detection**: Automatic local timezone detection
- **Time difference calculations**: Clear offset information between zones

## MCP Tools

### `get_current_time`

Get current time in a specific timezone or system timezone.

**Parameters:**
- `timezone` (string, required): IANA timezone name (e.g., 'America/New_York', 'Europe/London')

**Returns:**
- `timezone`: The requested timezone name
- `datetime`: ISO formatted datetime with timezone
- `day_of_week`: Full day name (e.g., "Monday")  
- `is_dst`: Boolean indicating if daylight saving time is active

**Example:**
```json
{
  "timezone": "Europe/Warsaw", 
  "datetime": "2024-01-01T13:00:00+01:00",
  "day_of_week": "Monday",
  "is_dst": false
}
```

### `convert_time`

Convert time between timezones with detailed comparison information.

**Parameters:**
- `source_timezone` (string, required): Source IANA timezone name
- `time` (string, required): Time in 24-hour format (HH:MM)
- `target_timezone` (string, required): Target IANA timezone name

**Returns:**
- `source`: TimeResult for source timezone
- `target`: TimeResult for target timezone  
- `time_difference`: Formatted offset between timezones (e.g., "+13.0h")

**Example:**
```json
{
  "source": {
    "timezone": "America/New_York",
    "datetime": "2024-01-01T16:30:00-05:00",
    "day_of_week": "Monday", 
    "is_dst": false
  },
  "target": {
    "timezone": "Asia/Tokyo",
    "datetime": "2024-01-02T06:30:00+09:00", 
    "day_of_week": "Tuesday",
    "is_dst": false
  },
  "time_difference": "+14.0h"
}
```

## Use Cases

Perfect for:
- **Global coordination**: Schedule meetings across timezones
- **Travel planning**: Calculate time differences for trips
- **System monitoring**: Track events across distributed systems
- **User localization**: Display times in user's preferred timezone
- **Deadline management**: Convert project deadlines to local time
- **Historical analysis**: Understand when events occurred in different zones

## Supported Timezones

Supports all IANA timezone names including:
- **Americas**: `America/New_York`, `America/Los_Angeles`, `America/Chicago`
- **Europe**: `Europe/London`, `Europe/Paris`, `Europe/Berlin`  
- **Asia**: `Asia/Tokyo`, `Asia/Shanghai`, `Asia/Kolkata`
- **Australia**: `Australia/Sydney`, `Australia/Melbourne`
- **Africa**: `Africa/Cairo`, `Africa/Johannesburg`
- **And many more**: Full IANA timezone database support

## Architecture

This tool wraps the official MCP Time server:
- **Base Image**: `mcp/time:latest`
- **Protocol**: HTTP-based MCP server on port 80
- **Dependencies**: None (uses system timezone database)
- **Storage**: Stateless (no persistent data)

## Integration

Agents can use this tool to:

1. **Answer time queries**: "What time is it in Tokyo?"
2. **Schedule coordination**: "When it's 4 PM in New York, what time is it in London?"
3. **Meeting planning**: Convert proposed times to attendee timezones
4. **Deadline tracking**: Show project deadlines in local time
5. **Event logging**: Record events with proper timezone context

The tool automatically handles daylight saving time transitions and provides clear, structured time information for any timezone-aware application.