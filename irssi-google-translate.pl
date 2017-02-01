# Translation via Google Translate API v2
#
# Copyright (c) 2017 Julien Künzi
#
# Licensed under the MIT License (MIT). See LICENSE for more information.
#
# Initial inspiration from https://github.com/vovcacik/irssi-scripts/blob/master/translate.pl
#

use strict;
use warnings;

use Irssi;
use Irssi::TextUI;
use Data::Dumper;
use List::Util qw( min );
use LWP::UserAgent;
use JSON;

# irssi script preamble
our $VERSION = '1.0';
our %IRSSI = (
	authors     => 'Julien Künzi <jlnknz@landho.io>',
	name        => 'irssi-google-translate.pl',
	description => 'Live or informational translation of incoming and outgoing messages',
	license     => 'The MIT License (MIT)',
	url         => 'https://github.com/jlnklnz'
);

our $COMMAND_NAME = 'translate';
our @VALID_MODES = ('none', 'info', 'live');
our @VALID_LANGUAGES = (
	'af', 'ar', 'be', 'bn', 'ca', 'cs', 'da', 'de', 'el', 'es',
	'et', 'fa', 'fi', 'fr', 'ga', 'hi', 'hr', 'it', 'iw', 'ja',
	'ka', 'ko', 'ms', 'nl', 'pt', 'ro', 'ru', 'sl', 'sq', 'sr',
	'sv', 'sw', 'ta', 'tl', 'uk', 'ur', 'vi', 'zh-CN', 'en'
);

# Settings
# Your Google Translation API key
Irssi::settings_add_str('i18n', 'i18n_google_api_key', '');
# Your language
Irssi::settings_add_str('i18n', 'i18n_my_lang', 'en');
# The language of the people you are currently talking to
Irssi::settings_add_str('i18n', 'i18n_your_lang', 'en');
# Operation mode: live translation ('live'), informational translation ('info'), or disabled ('none')
Irssi::settings_add_str('i18n', 'i18n_operation_mode', 'none');
# Power button: tells whether the scrit is active or not. The script is always disabled by at startup.
Irssi::settings_add_bool('i18n', 'i18n_enabled', 0);

# Initially disable
_set_enabled_flag(0);

# Print an informational message in the admin window
sub _info
{
	my ($msg) = @_;
	Irssi::print $msg, MSGLEVEL_CRAP;
}

# Print an error message in the admin window
sub _error
{
	my ($msg) = @_;
	Irssi::print "%r".$msg."%n", MSGLEVEL_CRAP
}

# Returns translated $message, (detected) source language and target language.
# @param $source_lang Language of the $message. Optional.
# @param $target_lang Language to which translate the $message. Required.
# copied from l
# FIXME mention attribution
sub _google_translate {
	my ($message, $target_lang) = @_;
	my $source_lang;

	my $ua = new LWP::UserAgent;
	$ua->default_header('X-HTTP-Method-Override' => 'GET');
	my $payload = {
		'key'    => Irssi::settings_get_str('i18n_google_api_key'),
		'q'      => $message,
		'target' => $target_lang,
		'format' => 'text'
	};
	# FIXME for now never set the source, but it costs. So let's see later if we can infer a local
	# FIXME method to help the online service?
	# FIXFME $payload->{source} = $source_lang if $source_lang && $source_lang ne $target_lang;

	my $response = $ua->post("https://www.googleapis.com/language/translate/v2", $payload);
	if ($response->is_success) {
		my $json = $response->decoded_content;
		my $decoded = decode_json $json;
		my $translation = $decoded->{'data'}->{'translations'}->[0]->{'translatedText'};
		$source_lang = $decoded->{'data'}->{'translations'}->[0]->{'detectedSourceLanguage'} || $source_lang;
		return $translation, $source_lang, $target_lang;
	} else {
		_error "$IRSSI{name}: Google responded with error: ".$response->status_line;
		_error "Request details:";
		print Dumper($payload);
		_error "Response content:";
		print Dumper($response->decoded_content);
		return "", $source_lang, $target_lang;
	}
}

# Set a persona language ('my' language or 'your' language)
sub _set_persona_lang
{
	my ($data, undef, undef, $persona) = @_;
	my $lang = (split /\s+/, $data)[0];
	if ($lang ~~ @VALID_LANGUAGES) {
		Irssi::settings_set_str('i18n_'.$persona.'_lang', $lang);
		command_info();
	}
	else {
		_error  "Invalid language. Cannot set ".$persona." language";
	}
}

# Change the enabled/disabled status
sub _set_enabled_flag
{
	my ($flag) = @_;
	Irssi::settings_set_bool('i18n_enabled', $flag);
	_info "I18n script is now %r".($flag ? "ACTIVE" : "INACTIVE")."%n";
	command_info();
}

# Command: nil
# Default command handler
sub command_nil
{
	my ($data) = @_;
	my ($arg1) = split(' ', $data);

	# Make 'add' the default subcommand if some arguments are given. Otherwise
	# run 'list'.
	if ($arg1) {
		&Irssi::command_runsub($COMMAND_NAME, @_);
	}
	else {
		command_info();
	}
}
# Command: info
# Display the current status of the script
sub command_info
{
	printf(
		"Current configuration:\n - My language: %s\n - Your language: %s\n - Operation mode: %s\n - Enabled: %s\n",
		Irssi::settings_get_str('i18n_my_lang'),
		Irssi::settings_get_str('i18n_your_lang'),
		Irssi::settings_get_str('i18n_operation_mode'),
			Irssi::settings_get_bool('i18n_enabled') ? "true" : "false"
	);
}

# Command: me
# Set my own language
sub command_change_my_lang
{
	push @_, 'my';
	_set_persona_lang(@_);
}

# Command: you
# Set your language (i.e the one of the person I am talking to)
sub command_change_your_lang
{
	push @_, 'your';
	_set_persona_lang(@_);
}

# Command: enable
# Enable translation
sub command_enable
{
	_set_enabled_flag(1);
}

# Command: disable
# Disable translation
sub command_disable
{
	_set_enabled_flag(0);
}

# Command: mode
# Change current mode of operation
sub command_change_mode
{
	my ($data) = @_;
	my $mode = (split /\s+/, $data)[0];
	if ($mode ~~ @VALID_MODES) {
		Irssi::settings_set_str('i18n_operation_mode', $mode);
		command_info();
	}
	else {
		_error "Invalid operation mode. Must be one of |".join ", ", @VALID_MODES."|.";
	}
}


# Signal: on_incoming_message
# Handle incoming messages
sub on_incoming_message
{
	my ($server, $original, $nick, $host, $channel_name) = @_;

	Irssi::settings_get_bool('i18n_enabled') or return;
	my $mode = Irssi::settings_get_str('i18n_operation_mode');
	$mode ne 'none' or return;

	my $my_language = Irssi::settings_get_str('i18n_my_lang') or return;

	my ($translation, $source_lang, $target_lang) = _google_translate($original, $my_language);
	$translation or return;

	if ($source_lang ne $target_lang) {
		my ($main_text, $hint_text) = ($original, '');

		# live mode: translation is more important
		if ($mode eq 'live') {
			($main_text, $hint_text) = ($translation, '⇦ '.$original);
		}
		# info mode: original is more important
		else {
			$hint_text = '≃ '.$translation;
		}

		Irssi::signal_continue($server, $main_text, $nick, $host, $channel_name);
		$server->print($channel_name || $nick, '%K'.(' ' x 3).$hint_text.'%n', MSGLEVEL_CLIENTCRAP);
	}
}

# Signal: on_outgoing_message
# Handle outgoing message
sub on_outgoing_message
{
	my ($original, $server, $item) = @_;

	Irssi::settings_get_bool('i18n_enabled') or return;
	my $mode = Irssi::settings_get_str('i18n_operation_mode');
	$mode ne 'none' or return;

	my $your_language = Irssi::settings_get_str('i18n_your_lang') or return;

	my ($translation, $source_lang, $target_lang) = _google_translate($original, $your_language);
	$translation or return;

	if ($source_lang ne $target_lang) {
		my ($to_send, $main_text, $hint_text);

		# live mode: original is more important
		if ($mode eq 'live') {
			($to_send, $main_text, $hint_text) = ($translation, $original, '⇨ '.$translation);
		}
		# info mode: original is more important
		else {
			($to_send, $main_text, $hint_text) = ($original, $original, '≃ '.$translation);
		}

		Irssi::signal_continue(
			$to_send,
			$server,
			$item
		);

		my $win = Irssi::active_win;
		my $view = $win->view;
		my $ypos = $view->{ypos};

		# reach last line
		my $line = Irssi::TextUI::TextBufferView::get_lines($view);
		my $last_line = $line;
		while ($line) {
			$last_line = $line;
			$line = Irssi::TextUI::Line::next($line);
		}
		my $text = Irssi::TextUI::Line::get_text($last_line, 0);
		my $prev = Irssi::TextUI::Line::prev($last_line);

		my $level =
			Irssi::MSGLEVEL_MSGS()
				+ Irssi::MSGLEVEL_PUBLIC()
				+ Irssi::MSGLEVEL_NO_ACT()
				+ Irssi::MSGLEVEL_NEVER();

		# remove the last line and replace with the appropriate text
		Irssi::TextUI::TextBufferView::remove_line($view, $last_line);
		my $window = Irssi::Server::window_find_item($server, $item->{name});
		$text =~ s/^([^>]+>).*$/$1 $main_text/;
		Irssi::UI::Window::print_after($window, $prev, $level, $text);
		$server->print($item->{name}, '%K'.(' ' x 3).$hint_text.'%n', MSGLEVEL_CLIENTCRAP);
		# scroll to bottom
		Irssi::TextUI::TextBufferView::clear($view);
		Irssi::TextUI::TextBufferView::scroll($view, - ($ypos + 1));
	}
}

# Register new commands
Irssi::command_bind($COMMAND_NAME, \&command_nil);
Irssi::command_bind($COMMAND_NAME.' info', \&command_info);
Irssi::command_bind($COMMAND_NAME.' me', \&command_change_my_lang);
Irssi::command_bind($COMMAND_NAME.' you', \&command_change_your_lang);
Irssi::command_bind($COMMAND_NAME.' enable', \&command_enable);
Irssi::command_bind($COMMAND_NAME.' disable', \&command_disable);
Irssi::command_bind($COMMAND_NAME.' mode', \&command_change_mode);

# Catch signals
Irssi::signal_add('message public', \&on_incoming_message);
Irssi::signal_add('message private', \&on_incoming_message);
Irssi::signal_add('send text', \&on_outgoing_message);
