# Irssi scripts

## irssi-google-translate.pl

### Inspiration

Initial inspiration from https://github.com/vovcacik/irssi-scripts/blob/master/translate.pl
Some code still comes from this script here and there. If you wish to have a script that allows configuring
the languages depending on the channel and persons you are talking to, rather use the above
script.

### Installation

````
$ cp irssi-google-translate.pl .irssi/scripts/
# launch irssi
> /script load irssi-google-translate.pl
# Setup Google Translation API key
> /set i18n_google_api_key <yourapikey>
````

### Usage


Current configuration and status:
````
/translate info
````

Configuration:
````
/translate me <languagecode>
	Set my language. Incoming messages will be translated
	into this language if possible.
	
/translate you <languagecode>
	Set the language of my fellow chatters. Your messages 
	will be translated into this language and optionally sent
	on the wire instead of your original message (see option
	below). .
	
/translate mode <none|info|live>
	If set to 'info', no translation will be sent on the wire, 
	but translations will be displayed to you.
	If set to 'live', outgoing messages will be translated before
	being sent to remote users.
````

Enabling and disabling:
````
/translate enable
/translate disable
	When the script loads, it is initially disabled.
	All other settings are persisted between instance runs.
````

### Example
````
# I speak English
/translate me en
# I want to translate things into Vietnamese
/translate you vi
# I use the tool as a language teaching helper, not for live conversations
/translate mode info
# And I activate it
/translate enable
````

### TODO
````
/translate msg <my-msg>
	Send a translated message ('live' mode) even if the script is 
	currently disabled.
	
issues with UTF-8 chars?
````

## License

````
MIT License

Copyright (c) 2017 Julien Künzi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
````