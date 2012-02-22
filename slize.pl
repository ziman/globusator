#!/usr/bin/perl -w

# slize.pl
# 
# Create globe stripes along meridians out of a (roughly) square map of a city.
# Author: Matus Tejiscak <functor.sk@ziman>
#
# The source map is projected using the stereographic projection onto the globe.
# After that, meridian stripes are created using Transverse Mercator.
#
# Licensed under BSD3.

use strict;
use warnings;
use Math::Round;

# Create one stripe
sub slizik {
	my ($cfg, $yaw, $outfile) = @_;

	# Generic options
	my $format = "JPEG c:$cfg->{quality}";

	# Pitch and roll
	my $pitch = 90; # city centre: equator/poles?
	my $roll  = 0;  # tilt

	# Calculate integral bounds
	my ($centerx, $dx) = (1.7207, 0.09 * 12 / $cfg->{stripes});
	my ($centery, $dy) = (0.8640, 0.5000);

	my $h     = $cfg->{height};
	my $imgw  = round(3.448 * $h);
	my $imgh  = round(1.724 * $h);
	my $left  = round(($centerx-$dx) * $h);
	my $right = round(($centerx+$dx) * $h);
	my $top   = round(($centery-$dy) * $h);
	my $bot   = round(($centery+$dy) * $h);

	# Generate the corresponding PTO file
	print "$outfile: ";
	print "PTO ";
	open my $F, ">$cfg->{ptofile}";
	print $F "p f6 w$imgw h$imgh v179 E0 R0 S$left,$right,$top,$bot n\"$format r:CROP\"\n";
	print $F "m g1 i0 f0 m2 p0.00784314\n";
	print $F "i w$cfg->{inw} h$cfg->{inh} f10 v292.152297783717 Ra0 Rb0 Rc0 Rd0 Re0 Eev0 Er1 Eb1 r$roll p$pitch";
	print $F "  y$yaw TrX0 TrY0 TrZ0 j0 a0 b0 c0 d0 e0 g0 t0 Va1 Vb0 Vc0 Vd0 Vx0 Vy0 Vm5 n\"$cfg->{srcfile}\"\n";
	print $F "v r0\nv p0\nv y0\nv\n";
	close $F;

	# Remap the image
	print "NONA ";
	system("nona -o $outfile $cfg->{ptofile}") == 0 or die "Could not remap image";

	# Crop the image
	print "POSTPROC ";
	system("mogrify "
		. "-quality $cfg->{quality} "
		. "-crop "
			. ($right-$left)."x".($bot-$top)
			. "+".$left."+".$top." "
		. "$outfile"
	) == 0 or die "Could not postprocess image.";
	
	print "- OK\n";
}

# Print... well, help.
sub print_help {
	my ($reason) = @_;

	print "$reason\n";
	print "Usage: ./slize.pl [--option arg] [--option arg] infile.jpg\n";
	print "\n";
	print "Some options can be found by reading the source code (sorry).\n";

	exit(0);
}

# Default config, >>optionlist<<
my %cfg = (
	outprefix => 'out',
	srcfile   => 'input.jpg',
	height    => 3600,
	stripes   => 12,
	ptofile	  => 'ptofile.pto',
	quality   => 95
);

# Process the cmdline
my $arg = shift;
if (not defined ($arg) or $arg eq '--help') {
	print_help("Help requested.");
}
while ($arg =~ /^--/)
{
	my $val = shift;
	print_help("The option --$arg requires a value to follow it!") unless defined $val;

	$arg =~ s/^--//;
	$cfg{$arg} = $val;
	$arg = shift;
}

print_help("The last argument must be the input image") unless defined $arg;
$cfg{srcfile} = $arg;

# Autodetect input image dimensions
unless (defined $cfg{inw})
{
	my $ident = `identify $cfg{srcfile}`;
	if (my ($w,$h) = $ident =~ /(\d+)x(\d+)/)
	{
		print "Autodetected input image size: ${w}x${h}\n";
		($cfg{inw}, $cfg{inh}) = ($w, $h);
	}
}

# Do the work
for my $i (0 .. $cfg{stripes}-1) {
	slizik(\%cfg, $i*360.0/$cfg{stripes}, sprintf("$cfg{outprefix}-%02d.jpg", $i));
}

print "Done.\n";
