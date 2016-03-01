#!/usr/bin/perl

use strict;
use Net::Domain::ExpireDate;

# Define which TLDs to check 
#my @tlds = ($ARGV[1]);
#my @tlds = ('com','net','org');

#my $domain = shift;
#my $domain = $ARGV[0];
my($domain, $tld) = split(/\./, $ARGV[0], 2);
my @tlds = ($tld);
chomp($domain);
$domain = lc($domain);

die "No base domain name given\n" unless ($domain);

$, = "\n"; # Easy array printing
my @domains = ();

print "Generating variants with missing letters\n";
push @domains,  @{ missing_letters($domain) };

print "Generating variants with double entered letters\n";
push @domains, @{ double_letters($domain) };

print "Generating variants with swapped letters\n";
push @domains,  @{ swap_letters($domain) };

print "Generating variants with mistyped letters\n";
push @domains,  @{ mistype_letters($domain) };

print "Sorting and throwing away dups\n";
my @results = @{(undup(\@domains))}; 

print "Results: $#results domains\n";
foreach my $result (@results) {
	foreach my $tld (@tlds) {
		my $domain = $result . '.' . $tld;
		my $expires = expire_date($domain, '%Y-%m-%d');
		if ($expires) {
#			print "Domain $domain expires on $expires\n";
		}
		else {
			print "Domain $domain is not registered\n";
		}
	}
}

# Sort results and remove dups (from Perl FAQ)
sub undup {
	my $list = shift;
	my @result = ();

	my %saw;
	undef %saw;
	@result = grep(!$saw{$_}++, @{ $list });

	return \@result;
}

# Miss one letter at a time
sub missing_letters {
	my $text = shift;
	my @result = ();

	for (my $pos = 0; $pos <= length($text); $pos++) {
		my @letters = split(//, $text);
		delete $letters[$pos];
		if (@letters) {
			my $word = join('', @letters);
			push @result, $word;
		}
	}

	return \@result;
}

# Double-type each letter
sub double_letters {
	my $text = shift;
	my @result = ();

	for (my $pos = 0; $pos <= length($text); $pos++) {
		my @letters = split(//, $text);
		my $letter = $letters[$pos];
		$letters[$pos] = $letter x 2;
		if (@letters) {
			my $word = join('', @letters);
			push @result, $word;
		}
	}

	return \@result;
}

# Swap each two letters at a time
sub swap_letters {
	my $text = shift;
	my @result = ();

	for (my $pos = 0; $pos <= length($text)-1; $pos++) {
		my @letters = split(//, $text);
		my $tmp = $letters[$pos];
		$letters[$pos] = $letters[$pos+1];
		$letters[$pos+1] = $tmp;
		if (@letters) {
			my $word = join('', @letters);
			push @result, $word;
		}

	}

	return \@result;
}

# Mistype each letter at a time
sub mistype_letters {
	my $text = shift;
	my @result = ();

	# Define 'wrong' letters for each letter in domain
	my %typos = (
				'1' => '2q',
				'2' => '13qw',
				'3' => '24we',
				'4' => '35er',
				'5' => '46rt',
				'6' => '57ty',
				'7' => '68yu',
				'8' => '79ui',
				'9' => '80io',
				'0' => '9op',
				'-' => '0p',
				'q' => '12wsa',
				'w' => '2qasde3',
				'e' => '3wsdfr4',
				'r' => '4edfgt5',
				't' => '5rfghy6',
				'y' => '6tghju7',
				'u' => '7yhjki8',
				'i' => '8ujklo9',
				'o' => '9iklp0',
				'p' => '0ol',
				'a' => 'qwsxz',
				's' => 'wazxde',
				'd' => 'esxcfr',
				'f' => 'rdcvgt',
				'g' => 'tfvbhy',
				'h' => 'ygbnju',
				'j' => 'uhnmki',
				'k' => 'ijmlo',
				'l' => 'okp',
				'z' => 'asx',
				'x' => 'zsdc',
				'c' => 'xdfv',
				'v' => 'cfgb',
				'b' => 'vghn',
				'n' => 'bhjm',
				'm' => 'njk',
	);

	for (my $pos = 0; $pos <= length($text); $pos++) {
		my @letters = split(//, $text);
		my @typos = split(//, $typos{ $letters[$pos] } );
		foreach my $typo (@typos) {
			$letters[$pos] = $typo;
			if (@letters) {
				my $word = join('', @letters);
				push @result, $word;
			}
		}
	}

	return \@result;
}
