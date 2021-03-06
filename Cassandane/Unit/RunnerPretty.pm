#!/usr/bin/perl
#
#  Copyright (c) 2011 Opera Software Australia Pty. Ltd.  All rights
#  reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#
#  3. The name "Opera Software Australia" must not be used to
#     endorse or promote products derived from this software without
#     prior written permission. For permission or any legal
#     details, please contact
# 	Opera Software Australia Pty. Ltd.
# 	Level 50, 120 Collins St
# 	Melbourne 3000
# 	Victoria
# 	Australia
#
#  4. Redistributions of any form whatsoever must retain the following
#     acknowledgment:
#     "This product includes software developed by Opera Software
#     Australia Pty. Ltd."
#
#  OPERA SOFTWARE AUSTRALIA DISCLAIMS ALL WARRANTIES WITH REGARD TO
#  THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
#  AND FITNESS, IN NO EVENT SHALL OPERA SOFTWARE AUSTRALIA BE LIABLE
#  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
#  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
#  OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

package Cassandane::Unit::RunnerPretty;
use strict;
use warnings;

use lib '.';
use base qw(Cassandane::Unit::Runner);

sub new
{
    my ($class, $params, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{_quiet} = 1 if $params->{quiet};
    return $self;
}

sub ansi
{
    my ($self, $codes, @args) = @_;
    my $isatty = -t $self->print_stream;

    my $ansi;

    $ansi .= "\e[" . join(',', @{$codes}) . 'm' if $isatty;
    $ansi .= join ('', @args);
    $ansi .= "\e[0m" if $isatty;

    return $ansi;
}

sub start_test
{
    my $self = shift;
    my $test = shift;
    # prevent the default action which is to print "."
}

sub add_pass
{
    my $self = shift;
    my $test = shift;
    $self->_print(_getpaddedname($test) . "[  " . $self->ansi([32], 'OK') . "  ]\n");
}

sub add_error
{
    my $self = shift;
    my $test = shift;
    $self->_print(_getpaddedname($test) . "[" . $self->ansi([31], 'ERROR') . " ]\n");
}

sub add_failure
{
    my $self = shift;
    my $test = shift;
    $self->_print(_getpaddedname($test) . "[" . $self->ansi([33], 'FAILED') . "]\n");
}

sub _getpaddedname
{
    my $test = shift;
    my $suite = ref($test);
    $suite =~ s/^Cassandane:://;

    my $testname = $test->{"Test::Unit::TestCase_name"};
    $testname =~ s/^test_//;

    my $res = "$suite.$testname";

    if (length($res) > 70) {
	$res = substr($res, 0, 67) . '...';
    }

    $res .= ' ' x (72 - length($res));

    return $res;
}

sub print_errors
{
    my $self = shift;
    return if $self->{_quiet};

    my ($result) = @_;
    return unless my $error_count = $result->error_count();
    my $msg = "\nThere " .
              ($error_count == 1 ?
                "was 1 error"
              : "were $error_count errors") .
              ":\n";
    $self->_print($msg);

    my $i = 0;
    for my $e (@{$result->errors()}) {
        my ($test, $errors) = split(/\n/, $e->to_string(), 2);
        chomp $errors;
        $i++;
        $self->_print($self->ansi([31], "$i) $test") . "\n$errors\n");
        $self->_print("\nAnnotations:\n", $e->object->annotations())
          if $e->object->annotations();
    }
}

sub print_failures
{
    my $self = shift;
    return if $self->{_quiet};

    my ($result) = @_;
    return unless my $failure_count = $result->failure_count;
    my $msg = "\nThere " .
              ($failure_count == 1 ?
                "was 1 failure"
              : "were $failure_count failures") .
              ":\n";
    $self->_print($msg);

    my $i = 0;
    for my $f (@{$result->failures()}) {
        my ($test, $failures) = split(/\n/, $f->to_string(), 2);
        chomp $failures;
        $self->_print("\n") if $i++;
        $self->_print($self->ansi([33], "$i) $test") . "\n$failures\n");
        $self->_print("\nAnnotations:\n", $f->object->annotations())
          if $f->object->annotations();
    }
}

1;
