# FuzzyBar personality files

A `.fuzzybar` file is a personality you write yourself: every word the
menubar shows, in a small JSON file. Import it from Preferences
(**Import…**, or drop the file on the Preferences window) and it appears in
the Personality picker below the built-in ones.

The quickest start is **Save as Template…**, which writes the personality
you're using now to a file you can edit. Spoken and Vague don't use the
table below, so choosing either one saves Classic instead.
[`Examples/Pirate.fuzzybar`](../Examples/Pirate.fuzzybar) is a complete one.

## The file

```json
{
  "version": 1,
  "name": "Pirate",
  "format": "{phrase} {hour}, arr",
  "slots": ["smack on", "a wee bit past", "ten past", "quarter past",
            "twenty past", "twenty-five past", "half past", "twenty-five 'fore",
            "twenty 'fore", "quarter 'fore", "ten 'fore", "nigh on"],
  "hours": ["twelve", "one", "two", "three", "four", "five",
            "six", "seven", "eight", "nine", "ten", "eleven"],
  "nextHourFrom": 7
}
```

| Key | Required | What it is |
| --- | --- | --- |
| `name` | yes | The name in the picker. |
| `slots` | yes | Exactly 12 phrases, one per five minutes. |
| `hours` | yes | 12 hour names starting at twelve, or 24 starting at midnight. |
| `format` | no | How the two halves join. Needs `{phrase}` and `{hour}`. Default `"{phrase} {hour}"`. |
| `nextHourFrom` | no | The slot where the hour named becomes the next one, 1 to 11. Default 7. |
| `version` | no | The format version, currently 1. |

### How a time is read

The minutes are rounded to the nearest five and pick a slot:

| Slot | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Minutes | 0–2 | 3–7 | 8–12 | 13–17 | 18–22 | 23–27 | 28–32 | 33–37 | 38–42 | 43–47 | 48–52 | 53–59 |

Slot 11 runs all the way to :59, so it's the "almost" slot: 8:58 is still
"nigh on nine", never "smack on nine" too early.

From slot `nextHourFrom` on, the hour is the next one: with the default 7,
8:35 is "twenty-five 'fore nine". German counts "fünf vor halb neun" at
8:25, so its value is 5.

Twelve `hours` are used for both halves of the day. Give 24 when they
differ, like "nine am" and "nine pm", or 24-hour styles like "2100 HOURS".

`format` puts the two together, so a language that says the hour first can
use `"{hour} {phrase}"`, and anything else in it, like `, arr`, is kept as
written.

## Things to know

- **Length.** The menubar has room for about 30 characters before the
  notch on some MacBooks hides the rest. FuzzyBar imports longer ones but
  says which reading is longest.
- **Updating.** Importing a file whose name matches one you already have
  replaces it, so edit, import again, and look at the menubar.
- **Special times** still win: at a special time, and at the first minute
  of the year, the menubar shows that instead.
- **Removing** one goes back to the built-in personality you had before.
- **Where it's kept.** FuzzyBar copies the contents into its preferences
  when you import, so moving or deleting the file afterwards changes
  nothing. It reads only the files you pick or drop, and writes only where
  you save a template.

## Sharing

The files are yours to share. FuzzyBar doesn't host or list any: whatever a
file says, you wrote it or got it from someone else.
